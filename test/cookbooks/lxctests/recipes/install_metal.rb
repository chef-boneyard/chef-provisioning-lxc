include_recipe 'lxctests::install_lxc'

chef_gem 'chef-metal' do
  source '/tmp/chef-metal-0.2.1.gem'
  version '0.2.1'
end

chef_gem 'chef-metal-lxc' do
  source '/tmp/chef-metal-lxc-0.1.gem'
  version '0.1'
end
