require 'chef_metal_lxc/lxc_driver'

ChefMetal.register_driver_class('lxc', ChefMetalLXC::LXCDriver)
