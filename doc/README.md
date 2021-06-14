# Fab-Manager's documentations

##### Table of contents

1. [User's manual](#users-manual)<br/>
2. [System administrator](#system-administrator)<br/>
2.1. [Upgrades procedures](#upgrades-procedures)<br/>
3. [Translator's documentation](#translators-documentation)<br/>
4. [Developer's documentation](#developers-documentation)<br/>
4.1. [Architecture](#architecture)<br/>
4.2. [How to setup a development environment](#how-to-setup-a-development-environment)<br/>
4.3. [Externals](#externals)<br/>
4.4. [Diagrams](#diagrams)<br/>

### User's manual
The following guide describes what you can do and how to use Fab-manager.
 - [Français](fr/guide_utilisation_fab_manager_v5.0.pdf)

### System administrator
The following guides are designed for the people that perform software maintenance.
- [Setup and update a production environment](production_readme.md)

- [Configuring the environment variables](environment.md)

- [Known issues with Fab-Manager](known-issues.md)

- [Advanced PostgreSQL usage](postgresql_readme.md)

- [Connecting a SSO using oAuth 2.0](sso_with_github.md)

- [Upgrade from Fab-manager v1.0](upgrade_v1.md)

#### Upgrades procedures
- [PostgreSQL](postgres_upgrade.md)
- [ElasticSearch](elastic_upgrade.md)

### Translator's documentation
If you intend to translate Fab-manager to a new, or an already supported language, you'll find here the information you need. 
- [Guide for translators](translation_readme.md)

### Developer's documentation
The following guides should help those who want to contribute to the code.
#### Architecture
- [Code architecture](architecture.md)

#### How to setup a development environment
- [With docker-compose](development_readme.md)

- [With vagrant](virtual-machine.md)

#### Externals
- [ElasticSearch mapping](elasticsearch.md)

- [Changing the database system](postgresql_readme.md#using-another-dbms)

#### Diagrams
- [Database diagram](database.svg)

- [Class diagram](class-diagram.svg)

- [Javascript dependencies](js-modules-dependencies.svg)

- [Ruby dependencies](gem-dependencies.svg)
