machine 'test' do
  recipe 'lxctests::install_metal'
  recipe 'lxctests::simple'
  converge true
end
