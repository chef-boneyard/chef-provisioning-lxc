require 'chef/provisioning/transport'
require 'lxc/extra'
require 'mixlib/shellout'
require 'lxc/extra/proxy_client_side'
require 'lxc/extra/proxy_server_side'
require 'lxc/extra/channel'
require 'uri'
require 'socket'

class Chef
  module Provisioning
    module LXCDriver
      class LXCTransport < Chef::Provisioning::Transport
        @@active_transports = []

        class LXCExecuteResult < Struct.new(:command, :options, :stdout, :stderr, :exitstatus)
          def error!
            raise "Error: '#{command}' failed with exit code #{exitstatus}.\nSTDOUT:#{stdout}\nSTDERR:#{stderr}" if exitstatus != 0
          end
        end

        attr_reader :name, :options, :lxc_path

        include Chef::Mixin::ShellOut

        def initialize(name, lxc_path, options={})
          @options = options
          @name = name
          @lxc_path = lxc_path
          @port_forwards = {}
          @@active_transports << self
        end

        def container
          @container ||= LXC::Container.new(name, lxc_path)
        end

        def rootfs
          container.config_item('lxc.rootfs')
        end

        def container_path(path)
          File.join(rootfs, path)
        end

        def execute(command, options = {})
          timeout = options[:timeout] || 3600
          Chef::Log.info("Executing #{command} on #{name}")
          container.execute(timeout: timeout) do
            cmd = Mixlib::ShellOut.new(command)
            cmd.timeout = timeout
            begin
              cmd.run_command
              LXCExecuteResult.new(command, {}, cmd.stdout, cmd.stderr, cmd.exitstatus)
            rescue Errno::ENOENT => e
              LXCExecuteResult.new(command, {} , '', e.message, 2)
            end
          end
        end

        def make_url_available_to_remote(local_url)
          uri = URI(local_url)
          uri_scheme = uri.scheme
          uri_scheme = nil if uri.scheme == 'chefzero'
          host = Socket.getaddrinfo(uri.host, uri_scheme, nil, :STREAM)[0][3]
          if host == '127.0.0.1' || host == '::1'
            unless @port_forwards[uri.port]

              Chef::Log.debug("Forwarding container port #{uri.port} to local port #{uri.port}")
              # Create the channel that will let the container and the host talk to each other
              channel = LXC::Extra::Channel.new

              # Start the container side of the proxy, listening for client connections
              pid = container.attach do
                begin
                  server = TCPServer.new(host, uri.port)
                  proxy = LXC::Extra::ProxyClientSide.new(channel, server)
                  proxy.start
                rescue
                  Chef::Log.error("ERROR in proxy (container side): #{$!}\n#{$!.backtrace.join("\n")}")
                  raise
                end
              end

              # Start the host side of the proxy, which contacts the real server
              thread = Thread.new do
                proxy = LXC::Extra::ProxyServerSide.new(channel) do
                  TCPSocket.new(host, uri.port)
                end
                proxy.start
              end

              Chef::Log.debug("Forwarded #{uri.port} on container #{name} to local port #{uri.port}.  Container listener id PID #{pid}")

              @port_forwards[uri.port] = [ pid, thread, channel ]
            end

          end
          local_url
        end

        def read_file(path)
          container.execute(wait: true) do
            if File.exists?(container_path(path))
              File.read(container_path(path))
            end
          end
        end

        def download_file(path, local_path)
          Chef::Log.debug("Copying file #{path} from #{name} to local #{local_path}")
          data = read_file(path)
          File.open(local_path, 'w') do |f|
            f.write(data)
          end
        end

        def write_file(path, content)
          container.execute(wait: true) do
            File.open(path, 'w') do |f|
              f.write(content)
            end
          end
        end

        def upload_file(local_path, path)
          write_file(path, File.read(local_path))
        end

        def disconnect
          @port_forwards.each_pair do |port, (pid, thread, channel)|
            Chef::Log.debug("stopping port forward #{port} for container #{name}")
            begin
              Chef::Log.debug("Killing PID #{pid}")
              Process.kill('KILL', pid)
            rescue
            end
            begin
              thread.kill
            rescue
            end
          end
          @port_forwards = {}
          @@active_transports.delete(self)
        end

        def available?
          container.running?
        end

        def self.disconnect_active_transports
          @@active_transports.to_a.dup.each do |transport|
            transport.disconnect
          end
        end
      end
    end
  end
end

at_exit do
  Chef::Provisioning::LXCDriver::LXCTransport.disconnect_active_transports
end
