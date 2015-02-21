require 'chef/provisioning'
with_driver 'lxc'
# default ubuntu template will install 14.04, where chef is not well tested, lets use 12.04
with_machine_options :template => 'ubuntu', :template_options=>['-r','precise']
machine 'simple'
