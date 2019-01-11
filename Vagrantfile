# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = 'ubuntu/xenial64'
  config.vm.network "private_network", ip: "192.168.100.100"
  config.ssh.forward_agent = true
  config.vm.provision "shell", path: "provision.sh"
  config.vm.provision "shell", inline: "sudo service nginx start", run: 'always'

  config.vm.provider "virtualbox" do |vb|
    vb.name = "mvc-starter"
    vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end
end
