#!/usr/bin/env zsh

# Set environmen values #######################################################

  # Virtual environment flag
  echo '# Set virtual environment flag' >> ~/.profile
  echo 'export VIRTUAL_DEV_ENV=true' >> ~/.profile
  echo "\n" >>  ~/.profile

  # Language configuration
  echo '# Set locale configuration' >> ~/.profile
  echo 'export LC_ALL=en_US.UTF-8' >> ~/.profile
  echo 'export LANG=en_US.UTF-8' >> ~/.profile
  echo 'export LANGUAGE=en_US.UTF-8' >> ~/.profile
  echo "\n" >>  ~/.profile

# Install and setup PostgreSQL ################################################

echo "***************************************************"
echo "Checking Postgres installation..."
echo "***************************************************"
if ! dpkg -s postgresql; then
  echo "Installing PostgreSQL"
  sudo apt update
  sudo apt install -y postgresql postgresql-contrib

  echo "Setting up user"
  sudo -u postgres bash -c "psql -c \"CREATE USER ubuntu WITH PASSWORD 'ubuntu';\""
  sudo -u postgres bash -c "psql -c \"ALTER USER ubuntu WITH SUPERUSER;\""

  echo "Setting up extensions to all schemas"
  sudo -u postgres bash -c "psql -c \"CREATE EXTENSION unaccent SCHEMA pg_catalog;\""
  sudo -u postgres bash -c "psql -c \"CREATE EXTENSION pg_trgm SCHEMA pg_catalog;\""
fi

echo "***************************************************"
echo "             Starting Postgres server              "
echo "***************************************************"
sudo service postgresql start


# Install Redis ###############################################################

echo "***************************************************"
echo "Checking Redis installation..."
echo "***************************************************"
if ! dpkg -s redis-server; then
  echo "Instalating Redis"
  sudo apt install -y redis-server
fi


# Install Imagemagick #########################################################

echo "***************************************************"
echo "Checking Imagemagik installation..."
echo "***************************************************"
if ! dpkg -s imagemagick; then
  sudo apt install -y imagemagick
else
  echo 'OK'
fi


# Install Elastic Search ######################################################

echo "***************************************************"
echo "Checking ElasticSearch installation..."
echo "***************************************************"
if ! dpkg -s elasticsearch; then
  sudo apt install -y openjdk-8-jre apt-transport-https
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
  echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
  sudo apt update && sudo apt install -y elasticsearch

  # This configuration limits ElasticSearch memory use inside the virtual machine
  sudo echo "node.master: true" >> /etc/elasticsearch/elasticsearch.yml
  sudo echo "node.data: false" >> /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's/#bootstrap.memory_lock: true/bootstrap.memory_lock: true/g' /etc/elasticsearch/elasticsearch.yml
  sudo sed -i 's/#ES_JAVA_OPTS=/ES_JAVA_OPTS="-Xms256m -Xmx256m"/g' /etc/default/elasticsearch

  sudo /bin/systemctl daemon-reload
  sudo /bin/systemctl enable elasticsearch.service
else
  echo 'OK'
fi


# Install Ngrok exposer ######################################################

echo "***************************************************"
echo "Checking for Ngrok... "
echo "***************************************************"
if ! ngrok; then
  sudo apt install -y unzip
  wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
  sudo unzip ngrok-stable-linux-amd64.zip -d /usr/local/bin
  rm -rf ngrok-stable-linux-amd64.zip
else
  echo "OK"
fi


# Install Node Version Manager ################################################

echo "***************************************************"
echo "Checking for NVM... "
echo "***************************************************"
if [[ ! -x "$HOME/.nvm" ]]; then
  wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

  echo '# Node Version Manager' >> ~/.profile
  echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.profile
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.profile
  echo "\n" >>  ~/.profile
  echo 'autoload -U add-zsh-hook' >> ~/.profile
  echo 'load-nvmrc() {' >> ~/.profile
  echo '  local node_version="$(nvm version)"' >> ~/.profile
  echo '  local nvmrc_path="$(nvm_find_nvmrc)"' >> ~/.profile
  echo "\n" >>  ~/.profile
  echo '  if [ -n "$nvmrc_path" ]; then' >> ~/.profile
  echo '    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")' >> ~/.profile
  echo "\n" >>  ~/.profile
  echo '    if [ "$nvmrc_node_version" = "N/A" ]; then' >> ~/.profile
  echo '      nvm install' >> ~/.profile
  echo '    elif [ "$nvmrc_node_version" != "$node_version" ]; then' >> ~/.profile
  echo '      nvm use' >> ~/.profile
  echo '    fi' >> ~/.profile
  echo '  elif [ "$node_version" != "$(nvm version default)" ]; then' >> ~/.profile
  echo '    echo "Reverting to nvm default version"' >> ~/.profile
  echo '    nvm use default' >> ~/.profile
  echo '  fi' >> ~/.profile
  echo '}' >> ~/.profile
  echo 'add-zsh-hook chpwd load-nvmrc' >> ~/.profile
  echo 'load-nvmrc' >> ~/.profile

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
else
  echo "OK"
fi


# Install Node.js #############################################################

echo "***************************************************"
echo "Checking for Node.js... "
echo "***************************************************"
if ! node --version; then
  nvm install stable
  nvm alias default stable
  nvm use default
else
  echo 'OK'
fi


# Ruby and Version Manager ####################################################

echo "***************************************************"
echo 'Cheking for Ruby... '
echo "***************************************************"
if ! ruby -v; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  sudo apt install -y libxml2 libxml2-dev libxslt1-dev libpq-dev
  \curl -sSL https://get.rvm.io | bash
  source /home/vagrant/.rvm/scripts/rvm
  rvm get head
  rvm install ruby-2.3.6
  rvm use ruby-2.3.6@global
  gem update --system --no-ri --no-rdoc
  gem update --no-ri --no-rdoc
  rvm use ruby-2.3.6 --default
else
  echo 'OK'
fi


# Cleaning up #################################################################

echo "***************************************************"
echo 'Removing unused software... '
echo "***************************************************"
rvm cleanup all
sudo apt autoremove
