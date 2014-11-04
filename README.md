# chef-provisioning-lxc

This is the LXC provisioner for chef-provisioning.

## Quick Start

To run the tests, which creates an Ubuntu machine and installs this into it:

```
gem install chef-provisioning
rake build
cd test/
chef-client -z vagrant.rb ubuntu12.rb test_machine.rb
```

## Basic Usage

```ruby
require 'chef/provisioning/lxc_driver/lxc_provisioner'
with_provisioner Chef::Provisioning::LXCDriver::LXCProvisioner.new
```

## Provisioner Creation

The provisioner represents lxc containers in a directory.

`Chef::Provisioning::LXCDriver::LXCProvisioner.new(...)`

### Arguments

**lxc_path** - path where the lxc containers will be located.  This ends up being a sort of namespace, since the machines' names must be unique under each path.

## Provisioning Options

To specify provisioning options that will be used with all subsequent `machine` definitions:

```ruby
with_provisioner_options :template => <template name>,
  :template_options => <arguments>
  :backing_store => <backing store>
```

These options correspond to the options in [lxc create](https://qa.linuxcontainers.org/master/current/doc/man/lxc-create.1.html):

* **template**: the LXC template name to use.
* **template_options**: An array of string arguments to pass to the template.
* **backing_store**: The backing store to use for the file system.
