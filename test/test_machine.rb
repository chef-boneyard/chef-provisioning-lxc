# TODO this sucks.  Give a way for the machine to get back to the host during the initial converge!
machine 'chef-metal-lxc-test'

machine_file "/tmp/chef-metal-0.2.1.gem" do
  machine 'chef-metal-lxc-test'
  local_path "#{File.dirname(__FILE__)}/../../chef-metal/pkg/chef-metal-0.2.1.gem"
end

machine_file "/tmp/chef-metal-lxc-0.1.gem" do
  machine 'chef-metal-lxc-test'
  local_path "#{File.dirname(__FILE__)}/../pkg/chef-metal-lxc-0.1.gem"
end

machine 'chef-metal-lxc-test' do
  recipe 'lxctests::install_metal'
  recipe 'lxctests::simple'
  converge true
end
