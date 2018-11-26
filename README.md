# FabManager

FabManager is the FabLab management solution. It is web-based, open-source and totally free.


##### Table of Contents
1. [Software stack](#software-stack)
2. [Contributing](#contributing)
3. [Setup a production environment](#setup-a-production-environment)
4. [Setup a development environment](#setup-a-development-environment)<br/>
4.1. [General Guidelines](#general-guidelines)<br/>
4.2. [Virtual Machine Instructions](#virtual-machine-instructions)
5. [PostgreSQL](#postgresql)<br/>
5.1. [Install PostgreSQL 9.4 on Ubuntu/Debian](#postgresql-on-debian)<br/>
5.2. [Install and launch PostgreSQL on MacOS X](#postgresql-on-macosx)<br/>
5.3. [Setup the FabManager database in PostgreSQL](#setup-fabmanager-in-postgresql)<br/>
5.4. [PostgreSQL Limitations](#postgresql-limitations)
6. [ElasticSearch](#elasticsearch)<br/>
6.1. [Install ElasticSearch on Ubuntu/Debian](#elasticsearch-on-debian)<br/>
6.2. [Install ElasticSearch on MacOS X](#elasticsearch-on-macosx)<br/>
6.3. [Setup ElasticSearch for the FabManager](#setup-fabmanager-in-elasticsearch)<br/>
6.4. [Backup and Restore](#backup-and-restore-elasticsearch)
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
- Git 1.9.1+
- Redis 2.8.4+
- Sidekiq 3.3.4+
- Elasticsearch 5.6
- PostgreSQL 9.4

<a name="contributing"></a>
## Contributing

Contributions are welcome. Please read [the contribution guidelines](CONTRIBUTING.md) for more information about the contribution process.

<a name="setup-a-production-environment"></a>
## Setup a production environment

To run fab-manager as a production application, this is highly recommended to use [Docker](https://www.docker.com/).
The procedure to follow is described in the [docker readme](docker/README.md).

<a name="setup-a-development-environment"></a>
## Setup a development environment

In you intend to run fab-manager on your local machine to contribute to the project development, you can set it up with the following procedure.
This procedure is not easy to follow so if you don't need to write some code for Fab-manager, please prefer the [docker installation method](docker/README.md).

<a name="general-guidelines"></a>
### General Guidelines

1. Install RVM, with the ruby version specified in the [.ruby-version file](.ruby-version).
   For more details about the process, please read the [official RVM documentation](http://rvm.io/rvm/install).
   If you're using ArchLinux, you may have to [read this](doc/archlinux_readme.md) before.
   
2. Install NVM, withe the node.js version specified in the [.nvmrc file](.nvmrc).
   For instructions about installing NVM, please refer to [the NVM readme](https://github.com/creationix/nvm#installation).
   
3. Install Yarn, the front-end package manager.
   Depending on your system, the installation process may differ, please read the [official Yarn documentation](https://yarnpkg.com/en/docs/install#debian-stable).

4. Retrieve the project from Git

   ```bash
   git clone https://github.com/LaCasemate/fab-manager.git
   ```

5. Install the software dependencies.
   First install [PostgreSQL](#postgresql) and [ElasticSearch](#elasticsearch) as specified in their respective documentations.
   Then install the other dependencies:
   - For Ubuntu/Debian:

   ```bash
   sudo apt-get install libpq-dev redis-server imagemagick
   ```
   - For MacOS X:

   ```bash
   brew install redis imagemagick
   ```

6. Init the RVM and NVM instances and check they were correctly configured

   ```bash
   cd fab-manager
   rvm current | grep -q `cat .ruby-version`@fab-manager && echo "ok"
   # Must print ok
   nvm use
   node --version | grep -q `cat .nvmrc` && echo "ok"
   # Must print ok
   ```

7. Install bundler in the current RVM gemset

   ```bash
   gem install bundler
   ```

8. Install the required ruby gems and javascript plugins

   ```bash
   bundle install
   yarn install
   ```

9. Create the default configuration files **and configure them!** (see the [environment configuration documentation](doc/environment.md))

   ```bash
   cp config/database.yml.default config/database.yml
   cp config/application.yml.default config/application.yml
   vi config/application.yml
   # or use your favorite text editor instead of vi (nano, ne...)
   ```

10. Build the database. You may have to follow the steps described in [the PostgreSQL configuration chapter](#setup-fabmanager-in-postgresql) before, if you don't already had done it.
   - **Warning**: **DO NOT** run `rake db:setup` instead of these commands, as this will not run some required raw SQL instructions.
   - **Please note**: Your password length must be between 8 and 128 characters, otherwise db:seed will be rejected. This is configured in [config/initializers/devise.rb](config/initializers/devise.rb) 

   ```bash
   rake db:create
   rake db:migrate
   ADMIN_EMAIL='youradminemail' ADMIN_PASSWORD='youradminpassword' rake db:seed
   ```

11. Create the pids folder used by Sidekiq. If you want to use a different location, you can configure it in `config/sidekiq.yml`

   ```bash
   mkdir -p tmp/pids
   ```

12. Start the development web server

   ```bash
   foreman s -p 3000
   ```

13. You should now be able to access your local development FabManager instance by accessing `http://localhost:3000` in your web browser.

14. You can login as the default administrator using the credentials defined previously.

15. Email notifications will be caught by MailCatcher.
    To see the emails sent by the platform, open your web browser at `http://localhost:1080` to access the MailCatcher interface.

<a name="virtual-machine-instructions"></a>
### Virtual Machine Instructions

These instructions allow to deploy a testing or development instance of Fab Manager inside a virtual
machine, with most of the software dependencies installed automatically and avoiding to install a lot
of software and services directly on the host computer.

**Note:** The provision scripts configure the sofware dependencies to play nice with each other while
they are inside the same virtual environment but said configuration is not optimized for a production
environment.

1. Install [Vagrant][vagrant] and [Virtual Box][virtualbox] (with the extension package).

2. Retrieve the project from Git

   ```bash
   git clone https://github.com/LaCasemate/fab-manager
   ```

3. From the project directory, run:

   ```bash
   vagrant up
   ```

4. Once the virtual machine finished building, reload it with:

   ```bash
   vagrant reload
   ```

5. Log into the virtual machine with:

   ```bash
   vagrant ssh
   ```

6. While logged in, navigate to the project folder and install the Gemfile
   dependencies:

   ```bash
   cd /vagrant
   bundle install
   ```

7. Set a directory for Sidekick pids:

   ```bash
   mkdir -p tmp/pids
   ```

8. Copy the default configuration files:

   ```bash
   cp config/database.yml.virtual config/database.yml
   cp config/application.yml.default config/application.yml
   ```

10. Set up the databases. (Note that you should provide the desired admin credentials and that these
    specific set of commands must be used to set up the database as some raw SQL instructions are
    included in the migrations. Password minimal length is 8 characters):

   ```bash
   rake db:create
   rake db:migrate
   ADMIN_EMAIL='youradminemail' ADMIN_PASSWORD='youradminpassword' rake db:seed
   rake fablab:es_build_stats
   ```

11. Start the application and visit `localhost:3000` on your browser to check that it works:

   ```bash
   foreman s -p 3000
   ```

<a name="postgresql"></a>
## PostgreSQL

<a name="postgresql-on-debian"></a>
### Install PostgreSQL 9.4 on Ubuntu/Debian

1. Create the file `/etc/apt/sources.list.d/pgdg.list`, and append it one your distribution source:
   ```bash
   sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
   ```


2. Import the repository signing key, and update the package lists

   ```bash
   wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
   sudo apt-get update
   ```

3. Install PostgreSQL 9.4

   ```bash
   sudo apt-get install postgresql-9.4
   ```

<a name="postgresql-on-macosx"></a>
### Install and launch PostgreSQL on MacOS X

This assumes you have [Homebrew](http://brew.sh/) installed on your system.
Otherwise, please follow the official instructions on the project's website.


1. Update brew and install PostgreSQL

   ```bash
   brew update
   brew install homebrew/versions/postgresql94
   ```

2. Launch PostgreSQL

  ```bash
  # Start postgresql at login with launchd
  ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
  # Load PostgreSQL now
  launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
  ```

<a name="setup-fabmanager-in-postgresql"></a>
### Setup the FabManager database in PostgreSQL

Before running `rake db:create`, you have to make sure that the user configured in [config/database.yml](config/database.yml.default) for the `development` environment exists.
To create it, please follow these instructions:

1. Run the PostgreSQL administration command line interface, logged as the postgres user
   - For Ubuntu/Debian:

   ```bash
   sudo -i -u postgres
   psql
   ```
   - For MacOS X:

   ```bash
   sudo psql -U $(whoami) postgres
   ```

   If you get an error running this command, please check your [pg_hba.conf](https://www.postgresql.org/docs/current/static/auth-pg-hba-conf.html) file.

2. Create a new user in PostgreSQL (in this example, the user will be named `sleede`)

   ```sql
   CREATE USER sleede;
   ```

3. Grant him the right to create databases

   ```sql
   ALTER ROLE sleede WITH CREATEDB;
   ```

4. Then, attribute a password to this user

   ```sql
   ALTER USER sleede WITH ENCRYPTED PASSWORD 'sleede';
   ```

5. Finally, have a look at the [PostgreSQL Limitations](#postgresql-limitations) section or some errors will occurs preventing you from finishing the installation procedure.

<a name="postgresql-limitations"></a>
### PostgreSQL Limitations

- While setting up the database, we'll need to activate two PostgreSQL extensions: [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html).
  This can only be achieved if the user, configured in `config/database.yml`, was granted the _SUPERUSER_ role **OR** if these extensions were white-listed.
  So here's your choices, mainly depending on your security requirements:
  - Use the default PostgreSQL super-user (postgres) as the database user of fab-manager.
  - Set your user as _SUPERUSER_; run the following command in `psql` (after replacing `sleede` with you user name):

    ```sql
    ALTER USER sleede WITH SUPERUSER;
    ```

  - Install and configure the PostgreSQL extension [pgextwlist](https://github.com/dimitri/pgextwlist).
    Please follow the instructions detailed on the extension website to whitelist `unaccent` and `trigram` for the user configured in `config/database.yml`.
- Some users may want to use another DBMS than PostgreSQL.
  This is currently not supported, because of some PostgreSQL specific instructions that cannot be efficiently handled with the ActiveRecord ORM:
  - `app/controllers/api/members_controllers.rb@list` is using `ILIKE`
  - `app/controllers/api/invoices_controllers.rb@list` is using `ILIKE` and `date_trunc()`
  - `db/migrate/20160613093842_create_unaccent_function.rb` is using [unaccent](https://www.postgresql.org/docs/current/static/unaccent.html) and [trigram](https://www.postgresql.org/docs/current/static/pgtrgm.html) modules and defines a PL/pgSQL function (`f_unaccent()`)
  - `app/controllers/api/members_controllers.rb@search` is using `f_unaccent()` (see above) and `regexp_replace()`
  - `db/migrate/20150604131525_add_meta_data_to_notifications.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype.
  - `db/migrate/20160915105234_add_transformation_to_o_auth2_mapping.rb` is using [jsonb](https://www.postgresql.org/docs/9.4/static/datatype-json.html), a PostgreSQL 9.4+ datatype.
- If you intend to contribute to the project code, you will need to run the test suite with `rake test`.
  This also requires your user to have the _SUPERUSER_ role.
  Please see the [known issues](#known-issues) section for more information about this.

<a name="elasticsearch"></a>
## ElasticSearch

ElasticSearch is a powerful search engine based on Apache Lucene combined with a NoSQL database used as a cache to index data and quickly process complex requests on it.

In FabManager, it is used for the admin's statistics module and to perform searches in projects.

<a name="elasticsearch-on-debian"></a>
### Install ElasticSearch on Ubuntu/Debian

For a more detailed guide concerning the ElasticSearch installation, please check the [official documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html)

1. Install the OpenJDK's Java Runtime Environment (JRE). ElasticSearch recommends that you install Java 8 update 131 or later.
   Please check that your distribution's version meet this requirement. 
   Using Ubuntu 14.04, see https://askubuntu.com/a/944260. With other systems, use the following command

  ```bash
  sudo apt-get install openjdk-8-jre
  ```
  
2. Install HTTPS support for aptitude
  ```bash
  sudo apt-get install apt-transport-https
  ```

3. Create the repository definition file
   ```bash
   echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
   ```

4. Import the repository signing key, and update the package lists

   ```bash
   wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
   sudo apt-get update
   ```

5. Install ElasticSearch 5.6

   ```bash
   sudo apt-get install elasticsearch
   ```

6. To automatically start ElasticSearch during bootup, then, depending if your system is compatible with SysV (eg. Ubuntu 14.04) or uses systemd (eg. Debian 8+/Ubuntu 16.04+), you will need to run:

   ```bash
   # System V
   sudo update-rc.d elasticsearch defaults 95 10
   # *** OR *** (systemd)
   sudo /bin/systemctl daemon-reload
   sudo /bin/systemctl enable elasticsearch.service
   ```

7. Restart the host operating system to complete the installation

   ```bash
   sudo reboot
   ```

<a name="elasticsearch-on-macosx"></a>
### Install ElasticSearch on MacOS X

This assumes you have [Homebrew](http://brew.sh/) installed on your system.
Otherwise, please follow the official instructions on the project's website.

```bash
brew update
brew install elasticsearch@5.6
```

<a name="setup-fabmanager-in-elasticsearch"></a>
### Setup ElasticSearch for the FabManager

1. Launch the associated rake tasks in the project folder.
   This will create the fields mappings in ElasticSearch DB

   ```bash
   rake fablab:es_build_stats
   ```

2. Every nights, the statistics for the day that just ended are built automatically at 01:00 (AM).
   See [schedule.yml](config/schedule.yml) to modify this behavior.
   If the scheduled task wasn't executed for any reason (eg. you are in a dev environment and your computer was turned off at 1 AM), you can force the statistics data generation in ElasticSearch, running the following command.

   ```bash
   # Here for the 50 last days
   rake fablab:generate_stats[50]
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

To prevent syntax mistakes while translating locale files, we **STRONGLY advise** you to use a text editor witch support syntax coloration for YML and Ruby.

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

You can configure your fab-manager to synchronize every project with the [Open Projects platform](https://github.com/LaCasemate/openlab-projects).
It's very simple and straightforward and in return, your users will be able to search over projects from all fab-manager instances from within your platform.
The deal is fair, you share your projects and as reward you benefits from projects of the whole community.

If you want to try it, you can visit [this fab-manager](https://fablab.lacasemate.fr/#!/projects) and see projects from different fab-managers.

To start using this awesome feature, there are a few steps:
- send a mail to **contact@fab-manager.com** asking for your Open Projects client's credentials and giving them the name of your fab-manager, they will give you an `OPENLAB_APP_ID` and an `OPENLAB_APP_SECRET`
- fill in the value of the keys in your `application.yml`
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

You can see an example on the [repo of navinum gamification plugin](https://github.com/LaCasemate/navinum-gamification)

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
        DETAIL:  Key (group_id)=(1) is not present in table "groups".
        : ...
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:11:in `block in transaction'
            test_after_commit (1.0.0) lib/test_after_commit/database_statements.rb:5:in `transaction'

  This is due to an ActiveRecord behavior witch disable referential integrity in PostgreSQL to load the fixtures.
  PostgreSQL will prevent any users to disable referential integrity on the fly if they doesn't have the `SUPERUSER` role.
  To fix that, logon as the `postgres` user and run the PostgreSQL shell (see [Setup the FabManager database in PostgreSQL](#setup-fabmanager-in-postgresql) for an example).
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


---
[vagrant]: https://www.vagrantup.com/downloads.html
[virtualbox]: https://www.virtualbox.org/wiki/Downloads
