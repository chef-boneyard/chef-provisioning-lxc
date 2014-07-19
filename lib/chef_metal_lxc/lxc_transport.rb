require 'chef_metal/transport'
require 'lxc/extra'
require 'chef/mixin/shell_out'
require 'lxc/extra/proxy_client_side'
require 'lxc/extra/proxy_server_side'
require 'lxc/extra/channel'
require 'uri'
require 'socket'

module ChefMetalLXC
  class LXCTransport < ChefMetal::Transport
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
      Chef::Log.info("Executing #{command} on #{name}")
      container.execute(:timeout => (execute_timeout(options) || 0)) do
        begin
          # TODO support streaming (shell out needs work)
          out = shell_out(command)
          Chef::Log.info(options.inspect)
          LXCExecuteResult.new(command, {}, out.stdout, out.stderr, out.exitstatus)
        rescue Exception => e
          LXCExecuteResult.new('', e.message, -1)
        end
      end
    end

    def make_url_available_to_remote(local_url)
      uri = URI(local_url)
      host = Socket.getaddrinfo(uri.host, uri.scheme, nil, :STREAM)[0][3]
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
      container.execute do
        if File.exists?(path)
          File.read(path)
        end
      end
    end

    def download_file(path, local_path)
      Chef::Log.debug("Copying file #{path} from #{name} to local #{local_path}")
      File.open(local_path, 'w') do |f|
        f.write(read_file)
      end
    end

    def write_file(path, content)
      container.execute do
        begin
          File.open(path, 'w') do |f|
            f.write(content)
          end
        rescue Exception => e
          LXCExecuteResult.new('', e.message, -1)
        end
      end
    end

    def upload_file(local_path, path)
      content = File.open(local_path){|f| f.read}
      container.execute do
        begin
          File.open(path, 'w') do |f|
            f.write(content)
          end
        rescue Exception => e
          LXCExecuteResult.new('', e.message, -1)
        end
      end
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
      begin
        execute('pwd')
        true
      rescue Exception =>e
        false
      end
    end

    def self.disconnect_active_transports
      @@active_transports.to_a.dup.each do |transport|
        transport.disconnect
      end
    end
  end
end

at_exit do
  ChefMetalLXC::LXCTransport.disconnect_active_transports
end
