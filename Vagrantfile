# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box     = "generic/centos8"

  config.vm.network "private_network", ip: "172.16.10.10"

  config.vm.synced_folder ".", "/vagrant",
    :owner => "vagrant", :group => "vagrant",
    :mount_options => ["dmode=777,fmode=777"]

  config.vm.provision "shell", path: "setup.sh"

end
