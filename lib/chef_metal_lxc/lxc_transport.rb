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
      @port_forwards = []
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
      container.execute do
        begin
          # TODO support streaming (shell out needs work)
          out = shell_out(command)
          LXCExecuteResult.new(command, options, out.stdout, out.stderr, out.exitstatus)
        rescue Exception => e
          LXCExecuteResult.new('', e.message, -1)
        end
      end
    end

    def make_url_available_to_remote(local_url)
      uri = URI(local_url)
      host = Socket.getaddrinfo(uri.host, uri.scheme, nil, :STREAM)[0][3]
      if host == '127.0.0.1' || host == '[::1]'

        Chef::Log.debug("Forwarding container port #{uri.port} to local port #{uri.port}")
        # Create the channel that will let the container and the host talk to each other
        channel = LXC::Extra::Channel.new

        # Start the container side of the proxy, listening for client connections
        pid = container.attach do
          begin
            server = TCPServer.new('127.0.0.1', uri.port)
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
            TCPSocket.new('127.0.0.1', uri.port)
          end
          proxy.start
        end

        @port_forwards << [ pid, thread, channel ]

      end
      local_url
    end

    def read_file(path)
      if File.exists?(container_path(path))
        File.read(container_path(path))
      end
    end

    def download_file(path, local_path)
      Chef::Log.debug("Copying file #{path} from #{name} to local #{local_path}")
      FileUtils.cp_r(container_path(path), local_path)
    end

    def write_file(path, content)
      File.open(container_path(path), 'w') do |f|
        f.write(content)
      end
    end

    def upload_file(local_path, path)
      FileUtils.cp_r(local_path, container_path(path))
    end

    def disconnect
      @port_forwards.each do |pid, thread, channel|
        begin
          Process.kill('KILL', pid)
        rescue
        end
        begin
          thread.kill
        rescue
        end
      end
      @port_forwards = []
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
