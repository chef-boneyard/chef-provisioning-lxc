require 'chef/mixin/shell_out'
require 'chef_metal/driver'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal_lxc/lxc_transport'
require 'chef_metal_lxc/version'
require 'lxc'
require 'shellwords'

module ChefMetalLXC
  # Provisions machines in lxc.
  class LXCDriver < ChefMetal::Driver

    include Chef::Mixin::ShellOut

    # URL scheme:
    # lxc:<path>
    # <path> defaults to LXC config 'lxc.lxcpath'
    # canonical URL calls realpath on <path>
    def self.from_url(driver_url, config)
      LXCDriver.new(driver_url, config)
    end

    def self.canonicalize_url(driver_url, config)
      scheme, lxc_path = driver_url.split(':', 2)
      if lxc_path.nil? || lxc_path == ':'
        lxc_path = LXC.global_config_item('lxc.lxcpath')
      end
      lxc_path = File.realpath(lxc_path)
      [ "lxc:#{lxc_path}", config ]
    end

    def initialize(driver_url, config)
      super
    end

    def lxc_path
      scheme, lxc_path = driver_url.split(':', 2)
      lxc_path
    end

    # Valid machine options:
    # :template - template name
    # :template_options - additional arguments for templates
    # :backingstore - backing storage (lvm, thinpools, btrfs etc)
    # :config_file - <path> path to LXC  file a la https://wiki.archlinux.org/index.php/Linux_Containers#Configuration_file
    # :extra_config - { 'key' => 'value', ... } a set of LXC config key/value pairs to individually set.  Merges with, and overrides any values in config_file.
    def allocate_machine(action_handler, machine_spec, machine_options)
      # Create the container if it does not exist
      if machine_spec.location
        ct = LXC::Container.new(machine_spec.location['name'], lxc_path)
      else
        ct = LXC::Container.new(machine_spec.name, lxc_path)
        if ct.defined?
          # Should this be a warning? Configurable, at least.
          raise "container #{machine_spec.name} already exists and is not managed by this LXC driver."
        end
      end

      unless ct.defined?
        action_handler.perform_action "create lxc container #{ct.name}" do
          #
          # Set config
          #
          # TODO if config file changes, reload container?
          if machine_options[:config_file]
            ct.load_config(machine_options[:config_file])
          end
          if machine_options[:extra_config]
            machine_options[:extra_config].each_pair do |key, value|
              ct.set_config_item(key, value)
            end
          end

          #
          # Create the machine
          #
          ct.create(machine_options[:template], machine_options[:backingstore], machine_options[:devspecs], 0, machine_options[:template_options])

          machine_spec.location = {
            'driver_url' => driver_url,
            'driver_version' => ChefMetalLXC::VERSION,
            'name' => machine_spec.name,
            'host_node' => action_handler.host_node,
            'allocated_at' => Time.now.utc.to_s
          }
        end
      end
    end

    def ready_machine(action_handler, machine_spec, machine_options)
      ct = LXC::Container.new(machine_spec.location['name'], lxc_path)

      # Unfreeze the frozen
      if ct.state == :frozen
        action_handler.perform_action "unfreeze lxc container #{machine_spec.location['name']} (state is #{ct.state})" do
          ct.unfreeze
        end
      end

      # Get stopped containers running
      unless ct.running?
        action_handler.perform_action "start lxc container #{machine_spec.location['name']} (state is #{ct.state})" do
          # Have to shell out to lxc-start for now, ct.start holds server sockets open!
          lxc_start = "lxc-start -d -n #{Shellwords.escape(machine_spec.location['name'])}"
# TODO add ability to change options on start
#          if machine_options[:config_file]
#            lxc_start << " -f #{Shellwords.escape(machine_options[:config_file])}"
#          end
#          if machine_options[:extra_config]
#            machine_options[:extra_config].each_pair do |key,value|
#              lxc_start << " -s #{Shellwords.escape("#{key}=#{value}")}"
#            end
#          end
          shell_out!(lxc_start)
#          ct.start
        end
      end

      # Create machine object for callers to use
      machine_for(machine_spec, machine_optionsß)
    end

    # Connect to machine without acquiring it
    def connect_to_machine(machine_spec, machine_options)
      machine_for(machine_spec, machine_options)
    end

    def destroy_machine(action_handler, machine_spec, machine_options)
      if machine_spec.location
        ct = LXC::Container.new(machine_spec.location['name'], lxc_path)
        if ct.defined?
          action_handler.perform_action "delete lxc container #{machine_spec.location['name']}" do
            ct.destroy
          end
        end
      end
      convergence_strategy_for(machine_options).cleanup_convergence(action_handler, machine_spec)
    end

    def stop_machine(action_handler, node)
      if machine_spec.location
        ct = LXC::Container.new(machine_spec.location['name'], lxc_path)
        if ct.running?
          action_handler.perform_action "delete lxc container #{machine_spec.location['name']}" do
            ct.stop
          end
        end
      end
    end

    protected

    def machine_for(machine_spec, machine_options)
      ChefMetal::Machine::UnixMachine.new(machine_spec, transport_for(machine_spec), convergence_strategy_for(machine_options))
    end

    def convergence_strategy_for(machine_spec, machine_options)
      ChefMetal::ConvergenceStrategy::InstallCached.new(machine_options[:convergence_options], config)
    end

    def transport_for(machine_spec)
      ChefMetalLXC::LXCTransport.new(machine_spec.location['name'], lxc_path)
    end
  end
end
