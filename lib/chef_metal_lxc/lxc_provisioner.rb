require 'chef/mixin/shell_out'
require 'chef_metal/provisioner'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal_lxc/lxc_transport'
require 'lxc'
require 'shellwords'

module ChefMetalLXC
  # Provisions machines in lxc.
  class LXCProvisioner < ChefMetal::Provisioner

    include Chef::Mixin::ShellOut

    def initialize(lxc_path = nil)
      @lxc_path = lxc_path || LXC.global_config_item('lxc.lxcpath')
    end

    attr_reader :lxc_path

    #
    # Acquire a machine, generally by provisioning it.  Returns a Machine
    # object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.  The Machine object will have a
    # "node" property which must be saved to the server (if it is any
    # different from the original node object).
    #
    # ## Parameters
    # provider - the provider object that is calling this method.
    # node - node object (deserialized json) representing this machine.  If
    #        the node has a provisioner_options hash in it, these will be used
    #        instead of options provided by the provisioner.  TODO compare and
    #        fail if different?
    #        node will have node['normal']['provisioner_options'] in it with any options.
    #        It is a hash with this format:
    #
    #           -- provisioner_url: lxc:<lxc_path>
    #           -- template: template name
    #           -- template_options: additional arguments for templates
    #           -- backingstore: backing storage (lvm, thinpools, btrfs etc)
    #           -- config_file: <path> path to LXC  file a la https://wiki.archlinux.org/index.php/Linux_Containers#Configuration_file
    #           -- extra_config: { 'key' => 'value', ... } a set of LXC config key/value pairs to individually set.  Merges with, and overrides any values in config_file.
    #
    #        node['normal']['provisioner_output'] will be populated with information
    #        about the created machine.  For lxc, it is a hash with this
    #        format:
    #
    #           -- provisioner_url: lxc:<lxc_path>
    #           -- name: container name
    #
    def acquire_machine(provider, node)
      # TODO verify that the existing provisioner_url in the node is the same as ours

      # Set up the modified node data
      provisioner_options = node['normal']['provisioner_options']
      provisioner_output = node['normal']['provisioner_output'] || {
        'provisioner_url' =>   "lxc:#{lxc_path}",
        'name' => node['name']
      }

      # Create the container if it does not exist
      ct = LXC::Container.new(provisioner_output['name'], lxc_path)
      unless ct.defined?
        provider.converge_by "create lxc container #{provisioner_output['name']}" do
          #
          # Set config
          #
          # TODO if config file changes, reload container?
          if provisioner_options['config_file']
            ct.load_config(provisioner_options['config_file'])
          end
          if provisioner_options['extra_config']
            provisioner_options['extra_config'].each_pair do |key, value|
              ct.set_config_item(key, value)
            end
          end

          #
          # Create the machine
          #
          ct.create(provisioner_options['template'], provisioner_options['backingstore'], 0, provisioner_options['template_options'])
        end
      end

      # Unfreeze the frozen
      if ct.state == :frozen
        provider.converge_by "unfreeze lxc container #{provisioner_output['name']} (state is #{ct.state})" do
          ct.unfreeze
        end
      end

      # Get stopped containers running
      unless ct.running?
        provider.converge_by "start lxc container #{provisioner_output['name']} (state is #{ct.state})" do
          # Have to shell out to lxc-start for now, ct.start holds server sockets open!
          lxc_start = "lxc-start -d -n #{Shellwords.escape(provisioner_output['name'])}"
# TODO add ability to change options on start
#          if provisioner_options['config_file']
#            lxc_start << " -f #{Shellwords.escape(provisioner_options['config_file'])}"
#          end
#          if provisioner_options['extra_config']
#            provisioner_options['extra_config'].each_pair do |key,value|
#              lxc_start << " -s #{Shellwords.escape("#{key}=#{value}")}"
#            end
#          end
          shell_out!(lxc_start)
#          ct.start
        end
      end

      node['normal']['provisioner_output'] = provisioner_output
      # Create machine object for callers to use
      machine_for(node)
    end

    # Connect to machine without acquiring it
    def connect_to_machine(node)
      machine_for(node)
    end

    def delete_machine(provider, node)
      if node['normal'] && node['normal']['provisioner_output']
        provisioner_output = node['normal']['provisioner_output']
        ct = LXC::Container.new(provisioner_output['name'], lxc_path)
        if ct.defined?
          provider.converge_by "delete lxc container #{provisioner_output['name']}" do
            ct.destroy
          end
        end
      end
      convergence_strategy_for(node).delete_chef_objects(provider, node)
    end

    def stop_machine(provider, node)
      provisioner_options = node['normal']['provisioner_options']
      if node['normal'] && node['normal']['provisioner_output']
        provisioner_output = node['normal']['provisioner_output']
        ct = LXC::Container.new(provisioner_output['name'], lxc_path)
        if ct.running?
          provider.converge_by "delete lxc container #{provisioner_output['name']}" do
            ct.stop
          end
        end
      end
    end

    protected

    def machine_for(node)
      ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
    end

    def convergence_strategy_for(node)
      @convergence_strategy ||= begin
        ChefMetal::ConvergenceStrategy::InstallCached.new
      end
    end

    def transport_for(node)
      provisioner_output = node['normal']['provisioner_output']
      ChefMetalLXC::LXCTransport.new(provisioner_output['name'], lxc_path)
    end
  end
end
