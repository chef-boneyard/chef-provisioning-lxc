# Use a Linux image
vagrant_box 'trusty64' do
  url 'https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box'
  provisioner_options 'vagrant_config' => <<EOM
    config.vm.synced_folder "../../..", "/mnt/host_src"
EOM
end
