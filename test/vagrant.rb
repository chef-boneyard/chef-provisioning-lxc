require 'cheffish'
require 'chef/provisioning_vagrant'

# Set up a vagrant cluster (place for vms) in ~/machinetest
vagrant_cluster "#{File.dirname(__FILE__)}/machinetest"

with_chef_local_server :chef_repo_path => File.dirname(__FILE__)
