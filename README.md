# README

This project is the FabLab Manager web application.

The purpose of this web application is to allow users to document their FabLab projects. The FabLab also have the ability 
to plan some events (workshops or courses) and to expose them to its users.

This product can be extended to be used as a complete internal management system for a FabLab.

The underlying technologies are:
- `Ruby on Rails` for the backend application (server RESTful API)
- `AngularJS` for the frontend application (web-based graphical user interface)



## 1. Configuration

The following files must be filled with the correct configuration to allow FabManager to run correctly:

- config/environments/production.rb
	- `mandrill` -> change this if you're using a different mailing system
	
- config/environments/staging.rb
	- `config.action_mailer.default_url_options` -> change the URL according to the staging deployment url 
	- `mandrill` -> change this if you're using a different mailing system

- config/application.yml
	- `DEVISE_KEY` -> generate any secret phrase to secure the Devise authentication. You can use the `$ rake secret` command for this purpose. 
	- `SECRET_KEY_BASE` -> generate any secret phrase here to prevent XSS attacks. You can use the `$ rake secret` command for this purpose.
	- `DEFAULT_MAIL_FROM` -> default e-mail address from which the emails are sent 
	- `MANDRILL_USERNAME` -> if you plan to use mandrill
	- `MANDRILL_APIKEY` -> if you plan to use mandrill
	- `TWITTER_NAME` -> twitter api configuration
	- `TWITTER_CONSUMER_KEY` -> twitter api configuration
	- `TWITTER_CONSUMER_SECRET` -> twitter api configuration
	- `TWITTER_ACCESS_TOKEN` -> twitter api configuration
	- `TWITTER_ACCESS_TOKEN_SECRET` -> twitter api configuration
	- `GOOGLE_ANALYTICS_ACCOUNT` -> Google analytics account identifier (if you want to use GA)
	- `APPLICATION_ROOT_URL` -> The public URL where you application is deployed in production (eg. fablab.lacasemate.com)

- config/mandrill.rb
	You may change this if you don't want to use mandrill as your production mailing system

- config/database.yml.default
	Copy/Paste this file to `config/database.yml` and modify the configuration according to your postgreSQL configuration

- config/disqus_api.yml
	Insert here your identifiers for the Disqus API



## 2. Setup a development environment

1. Install RVM with latest ruby version
	See http://rvm.io/rvm/install
  
2. Retrieve the project from Git
	`$ git clone git@github.com:LaCasemate/fab-manager.git`

3. Install the dependencies
	- Ubuntu: `$ sudo apt-get install libpq-dev postgresql redis-server imagemagick`
	- MacOS: `$ brew install postgresql redis imagemagick`
   
4. Init the RVM instance and check it was correctly configured 
	```
	$ cd fab-manager
	$ rvm current
	```
  
5. Setup the project requirements
	`$ bundle install`
  
6. Build the database. You may have to configure your postgreSQL instance before, as described in chapter `3.2 Setup the FabManager database in PostgreSQL`
	`$ rake db:setup`
  
7. Create the pids folder used by sidekiq. If you want to use a different location, you can configure it in `config/sidekiq.yml`
   	`$ mkdir -p tmp/pids`
  
8. Configure the application environment variables, as explained in chapter `1. Configuration`
  
9. Start the development web server
	`$ foreman s -p 3000`



## 3. PostgreSQL

### 3.1 Launch PostgreSQL on MacOS 
	
	$ ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
	$ launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
	
  The first command will start postgresql at login with launchd. The second will load postgresql now.

### 3.2 Setup the FabManager database in PostgreSQL

1. Login as the postgres user
	`$ sudo -i -u postgres`

2. Run the postgreSQL administration command line interface
	`$ psql`
  
3. Create a new user in postgres (in this example, the user will be named "sleede")
	`# CREATE USER sleede;`

4. Grant him the right to create databases
	`# ALTER ROLE sleede WITH CREATEDB;`
 
5. Then create the fablab database
	`# CREATE DATABASE fabmanager_development OWNER sleede;`
  
6. To finish, attribute a password to this user
	`# ALTER USER sleede WITH ENCRYPTED PASSWORD 'sleede';`
  
  

## 4. Known issue

  You may encounter the following error message when running the application for the first time:

  ```bash
  Uncaught exception: FATAL:  authentification peer échouée pour l'utilisateur « USERNAME »
  Exiting
  	.rvm/gems/ruby-2.2.1@fabmanager/gems/activerecord-4.2.1/lib/active_record/connection_adapters/postgresql_adapter.rb:651:in `initialize'
  	...
  ```
  
  To solve this issue, edit your `/etc/postgresql/9.4/main/pg_hba.conf` as root and replace the following:
  
  ```bash
  # comment over or replace...
  local   all             all                                     peer
  # ...by the following:
  local   all             all                                     trust
  ```
  
  Then, restart postgreSQL to validate the modification (`sudo service postgresql restart`).




## 5. Related Documentation
- Angular-Bootstrap: http://angular-ui.github.io/bootstrap/


## 6. Translations
- French translation is available on the branches [master](../tree/master) and [dev](../tree/dev)
- English translation is available on the branch [english](../tree/english)
