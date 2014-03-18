require 'chef_metal'
require 'chef_metal_lxc/lxc_provisioner'
with_provisioner ChefMetalLXC::LXCProvisioner.new
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
with_provisioner_options 'template' => 'ubuntu', 'template_options'=>['-r','precise']
machine 'simple'
