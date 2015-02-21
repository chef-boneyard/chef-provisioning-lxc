# chef-provisioning-lxc

This is the LXC provisioner for chef-provisioning.

## Quick Start

To run the tests, which creates an Ubuntu machine and installs this into it:

```
gem install chef-provisioning
rake build
cd test/
set -x CHEF_DRIVER 'lxc'
chef-client -z lxc.rb simple.rb
```

## Basic Usage

```ruby
require 'chef/provisioning'
machine 'mario' do
  recipe 'apache2'
end
```

## Machine Options

To specify provisioning options that will be used with all subsequent `machine` definitions:

```ruby
with_machine_options :template => <template name>,
  :template_options => <arguments>,
  :backing_store => <backing store>
```

These options correspond to the options in [lxc create](https://qa.linuxcontainers.org/master/current/doc/man/lxc-create.1.html):

* **template**: the LXC template name to use.
* **template_options**: An array of string arguments to pass to the template.
* **backing_store**: The backing store to use for the file system.
