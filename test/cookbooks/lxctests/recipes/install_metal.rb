# Ubuntu 12, not Ubuntu 14
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 12
  package 'python-software-properties' do
    action :nothing
  end.run_action(:install)
end

execute 'add-apt-repository ppa:ubuntu-lxc/daily' do
  action :nothing
end.run_action(:run)

execute 'apt-get update' do
  action :nothing
end.run_action(:run)

# Needed for Ubuntu 14, not Ubuntu 12
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 14
  package 'ruby1.9.1-dev' do
    action :nothing
  end.run_action(:upgrade)
end

package 'lxc' do
  action :nothing
end.run_action(:upgrade)

package 'lxc-dev' do
  action :nothing
end.run_action(:upgrade)

package 'lxc-templates' do
  action :nothing
end.run_action(:upgrade)

chef_gem 'chef-metal' do
  source '/tmp/chef-metal-0.2.1.gem'
  version '0.2.1'
end

chef_gem 'chef-metal-lxc' do
  source '/tmp/chef-metal-lxc-0.1.gem'
  version '0.1'
end
