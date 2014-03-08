# TODO this sucks.  Give a way for the machine to get back to the host during the initial converge!
machine 'test' do
  complete true # Needed for cases where we destroy the machine but not the node.  Not cool
end

machine_file "/tmp/chef-metal-0.2.1.gem" do
  machine 'test'
  local_path "#{File.dirname(__FILE__)}/../../chef-metal/pkg/chef-metal-0.2.1.gem"
end

machine_file "/tmp/chef-metal-lxc-0.1.gem" do
  machine 'test'
  local_path "#{File.dirname(__FILE__)}/../pkg/chef-metal-lxc-0.1.gem"
end

machine 'test' do
  recipe 'lxctests::install_metal'
  recipe 'lxctests::simple'
  converge true
end
