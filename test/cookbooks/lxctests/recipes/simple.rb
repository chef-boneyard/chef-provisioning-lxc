require 'chef/provisioning'

with_driver 'lxc'

directory '/tmp/chef-repo'
with_chef_local_server chef_repo_path: '/tmp/chef-repo'

machine 'simple' do
  machine_options(
    template: 'download',
    template_options: %w( -d ubuntu -a amd64 -r trusty )
  )
end
