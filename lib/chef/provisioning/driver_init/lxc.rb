require 'chef/provisioning/lxc_driver/lxc_driver'

Chef::Provisioning.register_driver_class('lxc', Chef::Provisioning::LXCDriver::Driver)
