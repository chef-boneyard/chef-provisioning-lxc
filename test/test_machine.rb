machine 'test' do
  recipe 'lxctests::install_chef_provisioning'
  recipe 'lxctests::simple'
  converge true
end
