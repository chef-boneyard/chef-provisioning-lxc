require 'chef/provisioning'
require 'chef/provisioning/lxc_driver/lxc_provisioner'
with_provisioner Chef::Provisioning::LXCDriver::LXCProvisioner.new
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
with_provisioner_options 'template' => 'ubuntu',
                         'template_options'=>['-r','precise'],
                         'config_file' => '/tmp/empty.conf',
                         'extra_config' => { 'lxc.network.type' => 'empty' }
file '/tmp/empty.conf' do
  content ''
end
machine 'simple'
