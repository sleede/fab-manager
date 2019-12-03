# FabManager

FabManager is the Fab Lab management solution. It provides a comprehensive, web-based, open-source tool to simplify your administrative tasks and your marker's projects.

[![Coverage Status](https://coveralls.io/repos/github/sleede/fab-manager/badge.svg)](https://coveralls.io/github/sleede/fab-manager)
[![Docker pulls](https://img.shields.io/docker/pulls/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/)
[![Docker Build Status](https://img.shields.io/docker/build/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/builds)

##### Table of Contents
1. [Software stack](#software-stack)
2. [Contributing](#contributing)
3. [Setup a production environment](#setup-a-production-environment)
4. [Setup a development environment](#setup-a-development-environment)
5. [Internationalization (i18n)](#i18n)
6. [Open Projects](#open-projects)
7. [Plugins](#plugins)
8. [Single Sign-On](#sso)
9. [Known issues](#known-issues)
10. [Related Documentation](#related-documentation)



<a name="software-stack"></a>
## Software stack

FabManager is a Ruby on Rails / AngularJS web application that runs on the following software:

- Ubuntu LTS 14.04+ / Debian 8+
- Ruby 2.3
- Redis 2.8.4+
- Sidekiq 3.3.4+
- Elasticsearch 5.6
- PostgreSQL 9.6

<a name="contributing"></a>
## Contributing

Contributions are welcome. Please read [the contribution guidelines](CONTRIBUTING.md) for more information about the contribution process.

<a name="setup-a-production-environment"></a>
## Setup a production environment

To run fab-manager as a production application, this is highly recommended to use [Docker-compose](https://docs.docker.com/compose/overview/).
The procedure to follow is described in the [docker-compose readme](doc/docker-compose_readme.md).

<a name="setup-a-development-environment"></a>
## Setup a development environment

In you intend to run fab-manager on your local machine to contribute to the project development, you can set it up by following the [development readme](doc/development_readme.md). 
This procedure relies on docker to set-up the dependencies.

Optionally, you can use a virtual development environment that relies on Vagrant and Virtual Box by following the [virtual machine instructions](virtual-machine.md).

<a name="i18n"></a>
## Internationalization (i18n)

The FabManager application can only run in a single language but this language can easily be changed.

Please refer to the [translation readme](doc/translation_readme.md) for instructions about configuring the language or to contribute to the translation.

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
- In some cases, the invoices won't be generated. This can be due to the image included in the invoice header not being supported.
  To fix this issue, change the image in the administrator interface (manage the invoices / invoices settings).
  See [this thread](https://forum.fab-manager.com/t/resolu-erreur-generation-facture/428) for more info.
  
- In the excel exports, if the cells expected to contain dates are showing strange numbers, check that you have correctly configured the [EXCEL_DATE_FORMAT](doc/environment.md#EXCEL_DATE_FORMAT) variable.

<a name="related-documentation"></a>
## Related Documentation

- [Ruby 2.3.0](http://ruby-doc.org/core-2.3.0/)
- [Ruby on Rails](http://api.rubyonrails.org)
- [AngularJS](https://docs.angularjs.org/api)
- [Angular-Bootstrap](http://angular-ui.github.io/bootstrap/)
- [ElasticSearch 5.6](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/index.html)
