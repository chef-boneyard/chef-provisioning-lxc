include_recipe 'lxctests::install_lxc'

chef_gem 'chef-provisioning' do
  compile_time true
end

chef_gem 'chef-provisioning-lxc' do
  compile_time true
end
