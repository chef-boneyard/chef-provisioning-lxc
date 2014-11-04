include_recipe 'lxctests::install_lxc'

chef_gem 'chef-provisioning' do
        action :install
end

chef_gem 'chef-provisioning-lxc' do
        action :install
end
