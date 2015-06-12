# chef-provisioning-lxc

This is the LXC provisioner for chef-provisioning.

## Quick Start

Assuming you have host with working LXC setup already, you can directly invoke an example recipe using chef localmode

- Clone chef-provisioning-lxc repo
```sh
git clone https://github.com/chef/chef-provisioning-lxc
```
- Run bundle install
```sh
bundle install
```
- Execute the test recipe to create a linux container

```sh
bundle exec chef-client -z -o recipe[lxctests::simple] -c test/client.rb
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
