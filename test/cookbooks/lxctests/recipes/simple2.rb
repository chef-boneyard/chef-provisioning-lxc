require 'chef/provisioning'

with_driver 'lxc'

directory '/tmp/chef-repo'
with_chef_local_server chef_repo_path: '/tmp/chef-repo'

with_machine_options :template => 'download',
                     :template_options => %w( -d ubuntu -a amd64 -r trusty ),
                     :config_file => '/tmp/empty.conf',
                     :extra_config => { 'lxc.network.type' => 'empty' }

file '/tmp/empty.conf' do
  content ''
end

machine 'simple2'
