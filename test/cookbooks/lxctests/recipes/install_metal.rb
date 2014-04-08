include_recipe 'lxctests::install_lxc'

chef_gem 'chef-metal' do
  source '/mnt/host_src/chef-metal/pkg/chef-metal-0.8.gem'
  version '0.8'
end

chef_gem 'chef-metal-lxc' do
  source '/mnt/host_src/chef-metal-lxc/pkg/chef-metal-lxc-0.3.gem'
  version '0.3'
end
