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

```
###
# set postgreSQL to valid password
###
sudo sed -i 's/all\s*peer/all md5/g' /etc/postgresql/*/main/pg_hba.conf
sudo service postgresql restart
```

1. Login as the postgres user
	`$ sudo -i -u postgres`

2. Run the postgreSQL administration command line interface
3. Create a new user in postgres (in this example, the user will be named "sleede")
4. Grant him the right to create databases
5. Then create the fablab database
6. To finish, attribute a password to this user
`psql -f /path/of/the/create_db_user.sql`
  

## 4. Know issues

  If you encounter a problem with bundler (unable to run `$ rails c` or `$ rails g`), you can fix it running the following commands:

	$ bundle pack
	$ bundle install --path vendor/cache



## 5. Related Documentation
- Angular-Bootstrap: http://angular-ui.github.io/bootstrap/

## Vagrant

You will need to install the Vagrant and Virtualbox first. After that you can setup develop enviroment by one command.

**Refrences:**

https://www.vagrantup.com/

https://gorails.com/guides/using-vagrant-for-rails-development

**Install plugin for Vagrant first:**

```
vagrant plugin install vagrant-librarian-chef-nochef
```

**How to start the Vagrant in project directory:**

```
vagrant up
```

**Start rails server:**
```
vagrant ssh -c /home/vagrant/serve
```

**Login VM:**
```
vagrant ssh
```

By default, Vagrant will share your project directory (the directory with the Vagrantfile) to `/vagrant`.

Notice: If bundle command fail when bootstrap, you can run it manually after login.
