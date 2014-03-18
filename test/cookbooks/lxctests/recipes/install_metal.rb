include_recipe 'lxctests::install_lxc'

chef_gem 'chef-metal' do
  source '/mnt/host_src/chef-metal/pkg/chef-metal-0.2.1.gem'
  version '0.2.1'
end

chef_gem 'chef-metal-lxc' do
  source '/mnt/host_src/chef-metal-lxc/pkg/chef-metal-lxc-0.2.gem'
  version '0.2'
end
