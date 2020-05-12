# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/bionic64'
  config.vm.define 'fabmanager-devbox'

  # Forward ports so services running in the virtual machine can be accessed by
  # the host
  [
    3000, # rails/puma
    9200, # elasticsearch
    5432, # postgres
    1080, # mailcatcher web ui
    4040  # ngrok web ui
  ].each do |port|
    config.vm.network 'forwarded_port', guest: port, host: port
  end

  # nginx server
  config.vm.network 'forwarded_port', guest: 80, host: 8080

  # Configuration to allocate resources fro the virtual machine
  config.vm.provider 'virtualbox' do |vb|
    vb.customize ['modifyvm', :id, '--memory', '2048']
  end

  # If you are using Windows o Linux with an encrypted volume stick with the
  # configuration below for file syncronization
  config.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

  # Copy default configuration files for the database connection and the Rails application
  config.vm.provision 'file', source: './config/database.yml.default', destination: '/vagrant/config/database.yml'
  config.vm.provision 'file', source: './env.example', destination: '/vagrant/.env'

  # Copy default configuration files to allow reviewing the Docker Compose integration
  config.vm.provision 'file', source: './docker/development/docker-compose.yml', destination: '/home/vagrant/docker-compose.yml'
  config.vm.provision 'file', source: './setup/env.example', destination: '/home/vagrant/config/env'
  config.vm.provision 'file', source: './setup/nginx.conf.example', destination: '/home/vagrant/config/nginx/fabmanager.conf'
  config.vm.provision 'file', source: './setup/elasticsearch.yml', destination: '/home/vagrant/elasticsearch/config/elasticsearch.yml'
  config.vm.provision 'file', source: './setup/log4j2.properties', destination: '/home/vagrant/elasticsearch/config/log4j2.properties'

  ## Provision software dependencies
  config.vm.provision 'shell', privileged: false, run: 'once',
                               path: 'provision/zsh_setup.sh'

  config.vm.provision 'shell', privileged: false, run: 'once',
                               path: 'provision/box_setup.zsh',
                               env: {
                                 'LC_ALL' => 'en_US.UTF-8',
                                 'LANG' => 'en_US.UTF-8',
                                 'LANGUAGE' => 'en_US.UTF-8'
                               }

  config.vm.provision 'shell', privileged: true, run: 'once',
                               path: 'provision/box_tuning.zsh'
end
