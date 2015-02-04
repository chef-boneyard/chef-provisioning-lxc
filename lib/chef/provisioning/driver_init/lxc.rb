require 'chef/provisioning/lxc_driver/driver'

Chef::Provisioning.register_driver_class('lxc', Chef::Provisioning::LXCDriver::Driver)
