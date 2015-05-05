server "fab-manager.com", :web, :app, :db, primary: true

set :domain, "fab-manager.com"
set :application, "fabmanager"
set :user, "admin"
set :port, 22
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:LaCasemate/fab-manager.git"
set :scm_user, "jarod022"
set :branch, "master"

set :rails_env, 'production'