# FabManager

FabManager is the FabLab management solution. It is web-based, open-source and totally free. 


##### Table of Contents  
1. [Software stack](#software-stack)
2. [Contributing](#contributing)
3. [Setup a development environment](#setup-a-development-environment)<br/>
3.1. [General Guidelines](#general-guidelines)<br/>
3.2. [Environment Configuration](#environment-configuration)
4. [PostgreSQL](#postgresql)<br/>
4.1. [Install PostgreSQL 9.4 on Ubuntu/Debian](#postgresql-on-debian)<br/>
4.2. [Install and launch PostgreSQL on MacOS X](#postgresql-on-macosx)<br/>
4.3. [Setup the FabManager database in PostgreSQL](#setup-fabmanager-in-postgresql)
5. [ElasticSearch](#elasticsearch)<br/>
5.1. [Install ElasticSearch on Ubuntu/Debian](#elasticsearch-on-debian)<br/>
5.2. [Install ElasticSearch on MacOS X](#elasticsearch-on-macosx)<br/>
5.3. [Setup ElasticSearch for the FabManager](#setup-fabmanager-in-elasticsearch)
6. [Internationalization (i18n)](#i18n)<br/>
6.1. [Translation](#i18n-translation)<br/>
6.1.1. [Front-end translations](#i18n-translation-front)<br/>
6.1.2. [Back-end translations](#i18n-translation-back)<br/>
6.2. [Configuration](#i18n-configuration)<br/>
6.2.1. [Settings](#i18n-settings)<br/>
6.2.2. [Applying changes](#i18n-apply)
7. [Known issues](#known-issues)
8. [Related Documentation](#related-documentation)



<a name="software-stack"></a>
## Software stack

FabManager is a Ruby on Rails / AngularJS web application that runs on the following software:

- Ubuntu/Debian
- Ruby 2.2.3
- Git 1.9.1+
- Redis 2.8.4+
- Sidekiq 3.3.4+
- Elasticsearch 1.7
- PostgreSQL 9.4

<a name="contributing"></a>
## Contributing

Contributions are welcome. Please read [the contribution guidelines](CONTRIBUTING.md) for more information about the contribution process.

**IMPORTANT**: **do not** update Arshaw/fullCalendar.js as it contains a hack for the remove-event cross.

<a name="setup-a-development-environment"></a>
## Setup a development environment

<a name="general-guidelines"></a>
### General Guidelines

1. Install RVM with the ruby version specified in the [.ruby-version file](.ruby-version).
   For more details about the process, Please read the [official RVM documentation](http://rvm.io/rvm/install).
  
2. Retrieve the project from Git

   ```bash
   git clone https://github.com/LaCasemate/fab-manager.git
   ```

3. Install the software dependencies.
   - For Ubuntu/Debian:
    
   ```bash
   sudo apt-get install libpq-dev postgresql-9.4 redis-server imagemagick
   ```
   - For MacOS X:
   
   ```bash
   brew install postgresql redis imagemagick
   ```
   
4. Init the RVM instance and check it was correctly configured
 
   ```bash
   cd fab-manager
   rvm current
   # Must print ruby-X.Y.Z@fab-manager (where X.Y.Z match the version in .ruby-version)
   ```
  
5. Install bundler in the current RVM gemset

   ```bash
   gem install bundler
   ```

6. Install the required ruby gems

   ```bash
   bundle install
   ```
  
7. Build the database. You may have to follow the steps described in [the PostgreSQL installation chapter](#postgresql) before, if you don't already have a working installation of PostgreSQL.

   ```bash
   rake db:setup
   ```
  
8. Create the pids folder used by Sidekiq. If you want to use a different location, you can configure it in `config/sidekiq.yml`

   ```bash
   mkdir -p tmp/pids
   ```
   
9. Create the default configuration file **and configure it !** (see the [Environment Configuration](#environment-configuration) section)
   
   ```bash
   cp config/application.yml.default config/application.yml
   vi config/application.yml 
   # or use your favorite editor instead of vi (nano, ne...)  
   ```
  
10. Start the development web server

   ```bash
   foreman s -p 3000
   ```
   
11. You should now be able to access your local development FabManager instance by accessing `http://localhost:3000` in your web browser.

12. You can login as the default administrator using the following credentials:
    - user: admin@fab-manager.com
    - password: adminadmin 

<a name="environment-configuration"></a>
### Environment Configuration

The settings in `config/application.yml` configure the environment variables of the application.
If you are in a development environment, your can keep the default values, otherwise, in production, values must be configured carefully.

    POSTGRES_HOST

DNS name or IP address of the server hosting the PostgreSQL database of the application (see [PostgreSQL](#postgresql)).

    POSTGRES_PASSWORD

Password for the PostgreSQL user, as specified in `database.yml`.
Please see [Setup the FabManager database in PostgreSQL](#setup-fabmanager-in-postgresql) for informations on how to create a user and set his password.

    REDIS_HOST

DNS name or IP address of the server hosting the redis database.

    ELASTICSEARCH_HOST

DNS name or IP address of the server hosting the elasticSearch database.

    SECRET_KEY_BASE

Used by the authentication system to generate random tokens, eg. for resetting passwords.
Used by Rails to generate the integrity of signed cookies.
You can generate such a random key by running `rake secret`.

    STRIPE_API_KEY & STRIPE_PUBLISHABLE_KEY

Key and secret used to identify you Stripe account through the API.
Retrieve them from https://dashboard.stripe.com/account/apikeys.

    STRIPE_CURRENCY

Currency used by stripe to charge the final customer. 
See https://support.stripe.com/questions/which-currencies-does-stripe-support for a list of available 3-letters ISO code.

**BEWARE**: stripe currency cannot be changed during the application life. 
Changing the currency after the application has already run, may result in several bugs and prevent the users to pay through stripe.
So set this setting carefully before starting the application for the first time.

    INVOICE_PREFIX

When payments are done on the platform, an invoice will be generate as a PDF file.
This value configure the prefix of the PDF file name.

    FABLAB_WITHOUT_PLANS

If set to 'true', the subscription plans will be fully disabled and invisible in the application.

    DEFAULT_MAIL_FROM

When sending notification mails, the platform will use this address to identify the sender.

    DELIVERY_METHOD

Configure the Rails' Action Mailer delivery method.
See http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.

    DEFAULT_HOST, DEFAULT_PROTOCOL, SMTP_ADDRESS, SMTP_PORT, SMTP_USER_NAME & SMTP_PASSWORD

When DELIVERY_METHOD is set to **smtp**, configure the SMTP server parameters.
See http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
DEFAULT_HOST is also used to configure Google Analytics.

    GA_ID

Identifier of your Google Analytics account.

    DISQUS_SHORTNAME

Unique identifier of your [Disqus](http://www.disqus.com) forum.
Disquq forums are used to allow visitors to comment on projects.
See https://help.disqus.com/customer/portal/articles/466208-what-s-a-shortname- for more informations.

    TWITTER_NAME

Identifier of the Twitter account, for witch the last tweet will be displayed on the home page.

    TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN & TWITTER_ACCESS_TOKEN_SECRET

Keys and secrets to access the twitter API.

    Settings related to i18n

See the [Settings](#i18n-settings) section of the [Internationalization (i18n)](#i18n) paragraph for a detailed description of these parameters.


<a name="postgresql"></a>
## PostgreSQL

<a name="postgresql-on-debian"></a>
### Install PostgreSQL 9.4 on Ubuntu/Debian

1. Create the file `/etc/apt/sources.list.d/pgdg.list`, and append it one the following lines:
   - `deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main` (Ubuntu 14.04 Trusty)
   - `deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main` (Debian 8 Jessie)
   

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
   brew install postgres
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

Before running `rake db:setup`, you have to make sure that the user configured in [config/database.yml](config/database.yml) for the `development` environment exists.
To create it, please follow these instructions:

1. Login as the postgres user

   ```bash
   sudo -i -u postgres
   ```

2. Run the PostgreSQL administration command line interface

   ```bash
   psql
   ```
  
3. Create a new user in PostgreSQL (in this example, the user will be named `sleede`)

   ```sql
   CREATE USER sleede;
   ```

4. Grant him the right to create databases

   ```sql
   ALTER ROLE sleede WITH CREATEDB;
   ```
 
5. Then, create the fablab_development and fablab_test databases

   ```sql
   CREATE DATABASE fablab_development OWNER sleede;
   CREATE DATABASE fablab_test OWNER sleede;
   ```
  
6. To finish, attribute a password to this user

   ```sql
   ALTER USER sleede WITH ENCRYPTED PASSWORD 'sleede';
   ```

<a name="elasticsearch"></a>
## ElasticSearch

ElasticSearch is a powerful search engine based on Apache Lucene combined with a NoSQL database used as a cache to index data and quickly process complex requests on it.

In FabManager, it is used for the admin's statistics module and to perform searches in projects. 

<a name="elasticsearch-on-debian"></a>
### Install ElasticSearch on Ubuntu/Debian

For a more detailed guide concerning the ElasticSearch installation, please check the [official documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html)

1. Install the OpenJDK's Java Runtime Environment (JRE). ElasticSearch recommends that you install Java 8 update 20 or later.
   Please check that your distribution's version meet this requirement.
  
  ```bash
  sudo apt-get install openjdk-8-jre
  ```
  
1. Create the file `/etc/apt/sources.list.d/elasticsearch-1.x.list`, and append it the following line:
   `deb http://packages.elastic.co/elasticsearch/1.x/debian stable main`
   
2. Import the repository signing key, and update the package lists

   ```bash
   wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
   sudo apt-get update
   ```

3. Install ElasticSearch 1.7

   ```bash
   sudo apt-get install elasticsearch
   ```
   
4. To automatically start ElasticSearch during bootup, then, depending if your system is compatible with SysV (eg. Ubuntu 14.04) or uses systemd (eg. Debian 8), you will need to run:
   
   ```bash
   # System V
   sudo update-rc.d elasticsearch defaults 95 10
   # *** OR *** (systemd)
   sudo /bin/systemctl daemon-reload
   sudo /bin/systemctl enable elasticsearch.service
   ```

<a name="elasticsearch-on-macosx"></a>
### Install ElasticSearch on MacOS X

This assumes you have [Homebrew](http://brew.sh/) installed on your system.
Otherwise, please follow the official instructions on the project's website.

```bash
brew update
brew install homebrew/versions/elasticsearch17
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
   If the scheduled task wasn't executed for any reason (eg. you are in a dev environment and your computer was turned off at 1 AM), you can force the statistics data generation in ElasticSearch, running the following commands in a rails console.
   
   ```bash
   rails c
   ```

   ```ruby
   # Here for the 200 last days
   200.times.each do |i|
      StatisticService.new.generate_statistic({start_date: i.day.ago.beginning_of_day,end_date: i.day.ago.end_of_day})
   end
   ```

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
These comments are not required to be translated, they are intended to help the translator to have some context informations about the sentence to translate.


<a name="i18n-configuration"></a>
### Configuration

Locales configurations are made in `config/application.yml`. 
If you are in a development environment, your can keep the default values, otherwise, in production, values must be configured carefully.

<a name="i18n-settings"></a>
#### Settings
    RAILS_LOCALE

Be sure that `config/locales/rails.XX.yml` exists, where `XX` match your configured rails_locale. 
You can find templates of these files at https://github.com/svenfuchs/rails-i18n/tree/rails-4-x/rails/locale.

Be aware that **this file MUST contain the CURRENCY symbol used to generate invoices** (among other things). 
Default is **en**.

    MOMENT_LOCALE
 
Configure the moment.js library for l10n. 

See `vendor/assets/components/moment/locale/*.js` for a list of available locales. 
Default is **en** (even if it's not listed).

    SUMMERNOTE_LOCALE

Configure the javascript summernote editor for l10n.

See `vendor/assets/components/summernote/lang/summernote-*.js` for a list of available locales. 
Default is **en-US** (even if it's not listed).

    ANGULAR_LOCALE

Configure the locale for angular-i18n.

Please, be aware that **the configured locale will imply the CURRENCY displayed to front-end users.**

_Eg.: configuring **fr-fr** will set the currency symbol to **€** but **fr-ca** will set **$** as currency symbol, so setting the `angular_locale` to simple **fr** (without country indication) will probably not do what you expect._

See `vendor/assets/components/angular-i18n/angular-locale_*.js` for a list of available locales. Default is **en**.

    MESSAGEFORMAT_LOCALE

Configure the messageformat.js library, used by angular-translate.

See vendor/assets/components/messageformat/locale/*.js for a list of available locales.

    FULLCALENDAR_LOCALE

Configure the fullCalendar JS agenda library.

See `vendor/assets/components/fullcalendar/dist/lang/*.js` for a list of available locales. Default is **en** (even if it's not listed).
  
    ELASTICSEARCH_LANGUAGE_ANALYZER

This configure the language analyzer for indexing and searching in projects with ElasticSearch.
See https://www.elastic.co/guide/en/elasticsearch/reference/1.7/analysis-lang-analyzer.html for a list of available analyzers (check that the doc version match your installed elasticSearch version).

    TIME_ZONE

In Rails: set Time.zone default to the specified zone and make Active Record auto-convert to this zone. Run `rake time:zones:all` for a list of available time zone names. 
Default is **UTC**.

    WEEK_STARTING_DAY

Configure the first day of the week in your locale zone (generally monday or sunday).
 
    D3_DATE_FORMAT

Date format for dates displayed in statistics charts. 
See https://github.com/mbostock/d3/wiki/Time-Formatting#format for available formats.

    UIB_DATE_FORMAT

Date format for dates displayed and parsed in date pickers.
See https://angular-ui.github.io/bootstrap/#uibdateparser-s-format-codes for a list available formats. 

**BEWARE**: years format with less than 4 digits will result in problems because the system won't be able to distinct dates with the same less significant digits, eg. 50 could mean 1950 or 2050.

<a name="i18n-apply"></a>
#### Applying changes

After modifying any values concerning the localisation, restart the application (ie. web server) to apply these changes in the i18n configuration.


<a name="known-issues"></a>
## Known issues

- When browsing a machine page, you may encounter an "InterceptError" in the console and the loading bar will stop loading before reaching its ending.
 This may append if the machine was created through a seed file without any image.
 To solve this, simply add an image to the machine's profile and refresh the web page.

- When starting the Ruby on Rails server (eg. `foreman s`) you may receive the following error:

        worker.1 | invalid url: redis::6379
        web.1    | Exiting
        worker.1 | ...lib/redis/client.rb...:in `_parse_options'

 This may happens when the `application.yml` file is missing. 
 To solve this issue copy `config/application.yml.default` to `config/application.yml`.
 This is required before the first start.
 
- Due to a stripe limitation, you won't be ble to create plans longer than one year.


<a name="related-documentation"></a>
## Related Documentation

- [Ruby 2.2.3](http://ruby-doc.org/core-2.2.3/)
- [Ruby on Rails](http://api.rubyonrails.org)
- [AngularJS](https://docs.angularjs.org/api)
- [Angular-Bootstrap](http://angular-ui.github.io/bootstrap/)
- [ElasticSearch 1.7](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/index.html)

