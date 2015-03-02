require 'chef/provisioning'
require 'chef/provisioning/lxc_driver'
::Chef::Config.from_file '/home/ranjib/workspace/foss/chef-provisioning-lxc/.chef/knife.rb'
with_driver 'lxc'
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
machine 'simple' do
  machine_options(
    template: 'download',
    template_options: %w{-d ubuntu -a amd64 -r trusty}
  )
end
