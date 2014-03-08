LXC provisioner for chef-metal

To run the tests:

```
gem install chef-metal
rake install
cd test/
chef-client -z vagrant.rb ubuntu12.rb test_machine.rb
