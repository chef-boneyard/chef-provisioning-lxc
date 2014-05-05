include_recipe 'lxctests::install_lxc'

chef_gem 'chef-metal' do
        action :install
end

chef_gem 'chef-metal-lxc' do
        action :install
end
