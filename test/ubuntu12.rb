# Use a Linux image
vagrant_box 'precise64' do
  url 'https://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box'
  provisioner_options 'vagrant_config' => <<EOM
    config.vm.synced_folder "../../..", "/mnt/host_src"
EOM
end
