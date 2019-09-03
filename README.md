# FabManager

FabManager is the Fab Lab management solution. It provides a comprehensive, web-based, open-source tool to simplify your administrative tasks and your marker's projects.

[![Coverage Status](https://coveralls.io/repos/github/sleede/fab-manager/badge.svg)](https://coveralls.io/github/sleede/fab-manager)
[![Docker pulls](https://img.shields.io/docker/pulls/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/)
[![Docker Build Status](https://img.shields.io/docker/build/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/builds)

##### Table of Contents
1. [Software stack](#software-stack)
2. [Contributing](#contributing)
3. [Setup a production environment](#setup-a-production-environment)
4. [Setup a development environment](#setup-a-development-environment)<br/>
4.1. [General Guidelines](#general-guidelines)<br/>
5. [PostgreSQL](#postgresql)<br/>
5.1. [Install PostgreSQL 9.4](#setup-postgresql)
6. [ElasticSearch](#elasticsearch)<br/>
6.1. [Install ElasticSearch](#setup-elasticsearch)<br/>
6.2. [Rebuild statistics](#rebuild-stats)<br/>
6.3. [Backup and Restore](#backup-and-restore-elasticsearch)
7. [Internationalization (i18n)](#i18n)<br/>
7.1. [Translation](#i18n-translation)<br/>
7.1.1. [Front-end translations](#i18n-translation-front)<br/>
7.1.2. [Back-end translations](#i18n-translation-back)<br/>
7.2. [Configuration](#i18n-configuration)<br/>
7.2.1. [Settings](#i18n-settings)<br/>
7.2.2. [Applying changes](#i18n-apply)
8. [Open Projects](#open-projects)
9. [Plugins](#plugins)
10. [Single Sign-On](#sso)
11. [Known issues](#known-issues)
12. [Related Documentation](#related-documentation)



<a name="software-stack"></a>
## Software stack

FabManager is a Ruby on Rails / AngularJS web application that runs on the following software:

- Ubuntu LTS 14.04+ / Debian 8+
- Ruby 2.3
- Redis 2.8.4+
- Sidekiq 3.3.4+
- Elasticsearch 5.6
- PostgreSQL 9.4

<a name="contributing"></a>
## Contributing

Contributions are welcome. Please read [the contribution guidelines](CONTRIBUTING.md) for more information about the contribution process.

<a name="setup-a-production-environment"></a>
## Setup a production environment

To run fab-manager as a production application, this is highly recommended to use [Docker-compose](https://docs.docker.com/compose/overview/).
The procedure to follow is described in the [docker-compose readme](docker/README.md).

<a name="setup-a-development-environment"></a>
## Setup a development environment

In you intend to run fab-manager on your local machine to contribute to the project development, you can set it up with the following procedure.

This procedure is not easy to follow so if you don't need to write some code for Fab-manager, please prefer the [docker-compose installation method](docker/README.md).

Optionally, you can use a virtual development environment that relies on Vagrant and Virtual Box by following the [virtual machine instructions](doc/virtual-machine.md).

<a name="general-guidelines"></a>
### General Guidelines

1. Install RVM, with the ruby version specified in the [.ruby-version file](.ruby-version).
   For more details about the process, please read the [official RVM documentation](http://rvm.io/rvm/install).
   If you're using ArchLinux, you may have to [read this](doc/archlinux_readme.md) before.

2. Install NVM, with the node.js version specified in the [.nvmrc file](.nvmrc).
   For instructions about installing NVM, please refer to [the NVM readme](https://github.com/creationix/nvm#installation).

3. Install Yarn, the front-end package manager.
   Depending on your system, the installation process may differ, please read the [official Yarn documentation](https://yarnpkg.com/en/docs/install#debian-stable).

4. Install docker.
   Your system may provide a pre-packaged version of docker in its repositories, but this version may be outdated.
   Please refer to [ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [debian](https://docs.docker.com/install/linux/docker-ce/debian/) or [MacOS](https://docs.docker.com/docker-for-mac/install/) documentation to setup a recent version of docker.

5. Add your current user to the docker group, to allow using docker without `sudo`.
   ```bash
   # add the docker group if it doesn't already exist
   sudo groupadd doker
   # add the current user to the docker group
   sudo usermod -aG docker $(whoami)
   # restart to validate changes
   sudo reboot
   ```

6. Create a docker network for fab-manager.
   You may have to change the network address if it is already in use.
   ```bash
   docker network create --subnet=172.18.0.0/16 fabmanager
   ```

7. Retrieve the project from Git

   ```bash
   git clone https://github.com/sleede/fab-manager.git
   ```

8. Install the software dependencies.
   First install [PostgreSQL](#postgresql) and [ElasticSearch](#elasticsearch) as specified in their respective documentations.
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

12. Create the default configuration files **and configure them!** (see the [environment configuration documentation](doc/environment.md))

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

16. You should now be able to access your local development FabManager instance by accessing `http://localhost:3000` in your web browser.

17. You can login as the default administrator using the credentials defined previously.

18. Email notifications will be caught by MailCatcher.
    To see the emails sent by the platform, open your web browser at `http://localhost:1080` to access the MailCatcher interface.


<a name="postgresql"></a>
## PostgreSQL

<a name="setup-postgresql"></a>
### Install PostgreSQL 9.4

We will use docker to easily install the required version of PostgreSQL.

1. Create the docker binding folder
   ```bash
   mkdir -p .docker/postgresql
   ```

2. Start the PostgreSQL container.
   ```bash
   docker run --restart=always -d --name fabmanager-postgres \
   -v $(pwd)/.docker/postgresql:/var/lib/postgresql/data \
   --network fabmanager --ip 172.18.0.2 \
   -p 5432:5432 \
   postgres:9.4
   ```

3. Configure fab-manager to use it.
   On linux systems, PostgreSQL will be available at 172.18.0.2.
   On MacOS, you'll have to set the host to 127.0.0.1 (or localhost).
   See [environment.md](doc/environment.md) for more details.

4 . Finally, you may want to have a look at detailed informations about PostgreSQL usage in fab-manager.
    Some information about that is available in the [PostgreSQL Readme](doc/postgresql_readme.md).

<a name="elasticsearch"></a>
## ElasticSearch

ElasticSearch is a powerful search engine based on Apache Lucene combined with a NoSQL database used as a cache to index data and quickly process complex requests on it.

In FabManager, it is used for the admin's statistics module and to perform searches in projects.

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
   ```bash
   docker run --restart=always -d --name fabmanager-elastic \
   -v $(pwd)/.docker/elasticsearch/config:/usr/share/elasticsearch/config \
   -v $(pwd)/.docker/elasticsearch:/usr/share/elasticsearch/data \
   -v $(pwd)/.docker/elasticsearch/plugins:/usr/share/elasticsearch/plugins \
   -v $(pwd)/.docker/elasticsearch/backups:/usr/share/elasticsearch/backups \
   --network fabmanager --ip 172.18.0.3 \
   -p 9200:9200 -p 9300:9300 \
   elasticsearch:5.6
   ```

4. Configure fab-manager to use it.
   On linux systems, ElasticSearch will be available at 172.18.0.3.
   On MacOS, you'll have to set the host to 127.0.0.1 (or localhost).
   See [environment.md](doc/environment.md) for more details.

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

<a name="i18n"></a>
## Internationalization (i18n)

The FabManager application can only run in a single language but this language can easily be changed.

<a name="i18n-translation"></a>
### Translation

Check the files located in `config/locales`:

- Front app translations (angular.js) are located in  `config/locales/app.scope.XX.yml`.
 Where scope has one the following meaning :
    - admin: translations of the administrator views (manage and configure the FabLab).
    - logged: translations of the end-user's views accessible only to connected users.
    - public: translation of end-user's views publicly accessible to anyone.
    - shared: translations shared by many views (like forms or buttons).
- Back app translations (Ruby on Rails) are located in  `config/locales/XX.yml`.
- Emails translations are located in `config/locales/mails.XX.yml`.
- Messages related to the authentication system are located in `config/locales/devise.XX.yml`.

If you plan to translate the application to a new locale, please consider that the reference translation is French.
Indeed, in some cases, the English texts/sentences can seems confuse or lack of context as they were originally translated from French.

To prevent syntax mistakes while translating locale files, we **STRONGLY advise** you to use a text editor which support syntax coloration for YML and Ruby.

<a name="i18n-translation-front"></a>
#### Front-end translations

Front-end translations uses [angular-translate](http://angular-translate.github.io) with some interpolations interpreted by angular.js and other interpreted by [MessageFormat](https://github.com/SlexAxton/messageformat.js/).
**These two kinds of interpolation use a near but different syntax witch SHOULD NOT be confused.**
Please refer to the official [angular-translate documentation](http://angular-translate.github.io/docs/#/guide/14_pluralization) before translating.

<a name="i18n-translation-back"></a>
#### Back-end translations

Back-end translations uses the [Ruby on Rails syntax](http://guides.rubyonrails.org/i18n.html) but some complex interpolations are interpreted by [MessageFormat](https://github.com/format-message/message-format-rb) and are marked as it in comments.
**DO NOT confuse the syntaxes.**

In each cases, some inline comments are included in the localisation files.
They can be recognized as they start with the sharp character (#).
These comments are not required to be translated, they are intended to help the translator to have some context information about the sentence to translate.

You will also need to translate the invoice watermark, located in `app/pdfs/data/`.
You'll find there the [GIMP source of the image](app/pdfs/data/watermark.xcf), which is using [Rubik Mono One](https://fonts.google.com/specimen/Rubik+Mono+One) as font.
Use it to generate a similar localised PNG image which keep the default image size, as PDF are not responsive.


<a name="i18n-configuration"></a>
### Configuration

Locales configurations are made in `config/application.yml`.
If you are in a development environment, your can keep the default values, otherwise, in production, values must be configured carefully.

<a name="i18n-settings"></a>
#### Settings

Please refer to the [environment configuration documentation](doc/environment.md#internationalization-settings)

<a name="i18n-apply"></a>
#### Applying changes

After modifying any values concerning the localisation, restart the application (ie. web server) to apply these changes in the i18n configuration.

<a name="open-projects"></a>
## Open Projects

**This configuration is optional.**

You can configure your fab-manager to synchronize every project with the [Open Projects platform](https://github.com/sleede/openlab-projects).
It's very simple and straightforward and in return, your users will be able to search over projects from all fab-manager instances from within your platform.
The deal is fair, you share your projects and as reward you benefits from projects of the whole community.

If you want to try it, you can visit [this fab-manager](https://fablab.lacasemate.fr/#!/projects) and see projects from different fab-managers.

To start using this awesome feature, there are a few steps:
- send a mail to **contact@fab-manager.com** asking for your Open Projects client's credentials and giving them the name of your fab-manager, they will give you an `OPENLAB_APP_ID` and an `OPENLAB_APP_SECRET`
- fill in the value of the keys in your environment file
- start your fab-manager app
- export your projects to open-projects (if you already have projects created on your fab-manager, unless you can skip that part) executing this command: `bundle exec rake fablab:openlab:bulk_export`

**IMPORTANT: please run your server in production mode.**

Go to your projects gallery and enjoy seeing your projects available from everywhere ! That's all.

<a name="plugins"></a>
## Plugins

Fab-manager has a system of plugins mainly inspired by [Discourse](https://github.com/discourse/discourse) architecture.

It enables you to write plugins which can:
- have its proper models and database tables
- have its proper assets (js & css)
- override existing behaviours of Fab-manager
- add features by adding views, controllers, ect...

To install a plugin, you just have to copy the plugin folder which contains its code into the folder `plugins` of Fab-manager.

You can see an example on the [repo of navinum gamification plugin](https://github.com/sleede/navinum-gamification)

<a name="sso"></a>
## Single Sign-On

Fab-manager can be connected to a [Single Sign-On](https://en.wikipedia.org/wiki/Single_sign-on) server which will provide its own authentication for the platform's users.
Currently OAuth 2 is the only supported protocol for SSO authentication.

For an example of how to use configure a SSO in Fab-manager, please read [sso_with_github.md](doc/sso_with_github.md).
Developers may find information on how to implement their own authentication protocol in [sso_authentication.md](doc/sso_authentication.md).

<a name="known-issues"></a>
## Known issues

- When browsing a machine page, you may encounter an "InterceptError" in the console and the loading bar will stop loading before reaching its ending.
  This may happen if the machine was created through a seed file without any image.
  To solve this, simply add an image to the machine's profile and refresh the web page.

- When starting the Ruby on Rails server (eg. `foreman s`) you may receive the following error:

        worker.1 | invalid url: redis::6379
        web.1    | Exiting
        worker.1 | ...lib/redis/client.rb...:in `_parse_options'

  This may happen when the `application.yml` file is missing.
  To solve this issue copy `config/application.yml.default` to `config/application.yml`.
  This is required before the first start.

- Due to a stripe limitation, you won't be able to create plans longer than one year.

- When running the tests suite with `rake test`, all tests may fail with errors similar to the following:

        Error:
        ...
        ActiveRecord::InvalidForeignKey: PG::ForeignKeyViolation: ERROR:  insert or update on table "..." violates foreign key constraint "fk_rails_..."
        DETAIL:  Key (group_id)=(1) is not present in table "...".
        : ...
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:11:in `block in transaction'
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:5:in `transaction'

  This is due to an ActiveRecord behavior witch disable referential integrity in PostgreSQL to load the fixtures.
  PostgreSQL will prevent any users to disable referential integrity on the fly if they doesn't have the `SUPERUSER` role.
  To fix that, logon as the `postgres` user and run the PostgreSQL shell (see [the dedicated section](#run-postgresql-cli) for instructions).
  Then, run the following command (replace `sleede` with your test database user, as specified in your database.yml):

        ALTER ROLE sleede WITH SUPERUSER;

  DO NOT do this in a production environment, unless you know what you're doing: this could lead to a serious security issue.

- With Ubuntu 16.04, ElasticSearch may refuse to start even after having configured the service with systemd.
  To solve this issue, you may have to set `START_DAEMON` to `true` in `/etc/default/elasticsearch`.
  Then reload ElasticSearch with:

  ```bash
  sudo systemctl restart elasticsearch.service
  ```

<a name="related-documentation"></a>
## Related Documentation

- [Ruby 2.3.0](http://ruby-doc.org/core-2.3.0/)
- [Ruby on Rails](http://api.rubyonrails.org)
- [AngularJS](https://docs.angularjs.org/api)
- [Angular-Bootstrap](http://angular-ui.github.io/bootstrap/)
- [ElasticSearch 5.6](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/index.html)
