# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box     = "CentOS6.4"
  config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20131103.box"

  config.vm.network "private_network", ip: "172.16.10.10"

  config.vm.synced_folder ".", "/vagrant",
    :owner => "vagrant", :group => "vagrant",
    :mount_options => ["dmode=777,fmode=777"]

  config.vm.provision "shell", path: "setup.sh"

end
