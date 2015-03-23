include_recipe 'apt'
include_recipe 'build-essential'

# Ubuntu 14+ ships with fresh enough LXC
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 12
  apt_repository 'ppa:ubuntu-lxc/stable' do
    action :nothing
  end.run_action(:add)
end

package 'lxc-dev' do
  action :nothing
end.run_action(:upgrade)

package 'lxc-templates' do
  action :nothing
end.run_action(:upgrade)
