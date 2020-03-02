# Install Fab-manager in a development environment with Docker

This document will guide you through all the steps needed to set up a development environment for Fab-manager.

##### Table of contents

1. [General Guidelines](#general-guidelines)<br/>
2. [PostgreSQL](#postgresql)<br/>
2.1. [Install PostgreSQL 9.6](#setup-postgresql)
3. [ElasticSearch](#elasticsearch)<br/>
3.1. [Install ElasticSearch](#setup-elasticsearch)<br/>
3.2. [Rebuild statistics](#rebuild-stats)<br/>
3.3. [Backup and Restore](#backup-and-restore-elasticsearch)

This procedure is not easy to follow so if you don't need to write some code for Fab-manager, please prefer the [docker-compose installation method](docker-compose_readme.md).


<a name="general-guidelines"></a>
## General Guidelines

1. Install RVM, with the ruby version specified in the [.ruby-version file](../.ruby-version).
   For more details about the process, please read the [official RVM documentation](http://rvm.io/rvm/install).
   If you're using ArchLinux, you may have to [read this](archlinux_readme.md) before.

2. Install NVM, with the node.js version specified in the [.nvmrc file](../.nvmrc).
   For instructions about installing NVM, please refer to [the NVM readme](https://github.com/nvm-sh/nvm#installation-and-update).

3. Install Yarn, the front-end package manager.
   Depending on your system, the installation process may differ, please read the [official Yarn documentation](https://yarnpkg.com/en/docs/install#debian-stable).

4. Install docker.
   Your system may provide a pre-packaged version of docker in its repositories, but this version may be outdated.
   Please refer to [ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [debian](https://docs.docker.com/install/linux/docker-ce/debian/) or [MacOS](https://docs.docker.com/docker-for-mac/install/) documentation to setup a recent version of docker.

5. Add your current user to the docker group, to allow using docker without `sudo`.
   ```bash
   # add the docker group if it doesn't already exist
   sudo groupadd docker
   # add the current user to the docker group
   sudo usermod -aG docker $(whoami)
   # restart to validate changes
   sudo reboot
   ```

6. Create a docker network for Fab-manager.
   You may have to change the network address if it is already in use.
   > 🍏 If you're using MacOS, this is not required.
   ```bash
   docker network create --subnet=172.18.0.0/16 fabmanager
   ```

7. Retrieve the project from Git

   ```bash
   git clone https://github.com/sleede/fab-manager.git
   ```

8. Install the software dependencies.
   First install [PostgreSQL](#postgresql) and [ElasticSearch](#elasticsearch) as specified in their respective documentations (see below).
   Then install the other dependencies:
   - For Ubuntu/Debian:

   ```bash
   # on Ubuntu 18.04 server, you may have to enable the "universe" repository
   sudo add-apt-repository universe
   # then, install the dependencies
   sudo apt-get install libpq-dev redis-server imagemagick
   ```
   - For MacOS X:

   ```bash
   brew install redis imagemagick
   ```

9. Init the RVM and NVM instances and check they were correctly configured

   ```bash
   cd fab-manager
   rvm current | grep -q `cat .ruby-version`@fab-manager && echo "ok"
   # Must print ok
   nvm use
   node --version | grep -q `cat .nvmrc` && echo "ok"
   # Must print ok
   ```

10. Install bundler in the current RVM gemset

   ```bash
   gem install bundler --version=1.17.3
   ```

11. Install the required ruby gems and javascript plugins

   ```bash
   bundle install
   yarn install
   ```

12. Create the default configuration files **and configure them!** (see the [environment configuration documentation](environment.md))

   ```bash
   cp config/database.yml.default config/database.yml
   cp config/application.yml.default config/application.yml
   vi config/application.yml
   # or use your favorite text editor instead of vi (nano, ne...)
   ```

13. Build the databases.
   - **Warning**: **DO NOT** run `rake db:setup` instead of these commands, as this will not run some required raw SQL instructions.
   - **Please note**: Your password length must be between 8 and 128 characters, otherwise db:seed will be rejected. This is configured in [config/initializers/devise.rb](config/initializers/devise.rb)

   ```bash
   # for dev
   rake db:create
   rake db:migrate
   ADMIN_EMAIL='youradminemail' ADMIN_PASSWORD='youradminpassword' rake db:seed
   rake fablab:es:build_stats
   # for tests
   RAILS_ENV=test rake db:create
   RAILS_ENV=test rake db:migrate
   ```

14. Create the pids folder used by Sidekiq. If you want to use a different location, you can configure it in `config/sidekiq.yml`

   ```bash
   mkdir -p tmp/pids
   ```

15. Start the development web server

   ```bash
   foreman s -p 3000
   ```

16. You should now be able to access your local development Fab-manager instance by accessing `http://localhost:3000` in your web browser.

17. You can login as the default administrator using the credentials defined previously.

18. Email notifications will be caught by MailCatcher.
    To see the emails sent by the platform, open your web browser at `http://localhost:1080` to access the MailCatcher interface.


<a name="postgresql"></a>
## PostgreSQL

<a name="setup-postgresql"></a>
### Install PostgreSQL 9.6

We will use docker to easily install the required version of PostgreSQL.

1. Create the docker binding folder
   ```bash
   mkdir -p .docker/postgresql
   ```

2. Start the PostgreSQL container.
   > 🍏 If you're using MacOS, remove the --network and --ip parameters, and add -p 5432:5432.
   ```bash
   docker run --restart=always -d --name fabmanager-postgres \
   -v $(pwd)/.docker/postgresql:/var/lib/postgresql/data \
   --network fabmanager --ip 172.18.0.2 \
   postgres:9.6
   ```

3. Configure Fab-manager to use it.
   On linux systems, PostgreSQL will be available at 172.18.0.2.
   On MacOS, you'll have to set the host to 127.0.0.1 (or localhost).
   See [environment.md](environment.md) for more details.

4 . Finally, you may want to have a look at detailed informations about PostgreSQL usage in Fab-manager.
    Some information about that is available in the [PostgreSQL Readme](postgresql_readme.md).

<a name="elasticsearch"></a>
## ElasticSearch

ElasticSearch is a powerful search engine based on Apache Lucene combined with a NoSQL database used as a cache to index data and quickly process complex requests on it.

In Fab-manager, it is used for the admin's statistics module and to perform searches in projects.

<a name="setup-elasticsearch"></a>
### Install ElasticSearch

1. Create the docker binding folders
   ```bash
   mkdir -p .docker/elasticsearch/config
   mkdir -p .docker/elasticsearch/plugins
   mkdir -p .docker/elasticsearch/backups
   ```

2. Copy the default configuration files
   ```bash
   cp docker/elasticsearch.yml .docker/elasticsearch/config
   cp docker/log4j2.properties .docker/elasticsearch/config
   ```

3. Start the ElasticSearch container.
   > 🍏 If you're using MacOS, remove the --network and --ip parameters, and add -p 9200:9200.
   ```bash
   docker run --restart=always -d --name fabmanager-elastic \
   -v $(pwd)/.docker/elasticsearch/config:/usr/share/elasticsearch/config \
   -v $(pwd)/.docker/elasticsearch:/usr/share/elasticsearch/data \
   -v $(pwd)/.docker/elasticsearch/plugins:/usr/share/elasticsearch/plugins \
   -v $(pwd)/.docker/elasticsearch/backups:/usr/share/elasticsearch/backups \
   --network fabmanager --ip 172.18.0.3 \
   elasticsearch:5.6
   ```

4. Configure Fab-manager to use it.
   On linux systems, ElasticSearch will be available at 172.18.0.3.
   On MacOS, you'll have to set the host to 127.0.0.1 (or localhost).
   See [environment.md](environment.md) for more details.

<a name="rebuild-stats"></a>
### Rebuild statistics

Every nights, the statistics for the day that just ended are built automatically at 01:00 (AM) and stored in ElastricSearch.
See [schedule.yml](config/schedule.yml) to modify this behavior.
If the scheduled task wasn't executed for any reason (eg. you are in a dev environment and your computer was turned off at 1 AM), you can force the statistics data generation in ElasticSearch, running the following command.

```bash
# Here for the 50 last days
rake fablab:es:generate_stats[50]
```

<a name="backup-and-restore-elasticsearch"></a>
### Backup and Restore

To backup and restore the ElasticSearch database, use the [elasticsearch-dump](https://github.com/taskrabbit/elasticsearch-dump) tool.

Dump the database with: `elasticdump --input=http://localhost:9200/stats --output=fablab_stats.json`.
Restore it with: `elasticdump --input=fablab_stats.json --output=http://localhost:9200/stats`.
