require 'chef/provisioning'
with_driver 'lxc'
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
machine 'simple' do
  machine_options(
    template: 'download',
    template_options: %w{-d ubuntu -a amd64 -r trusty}
  )
end
