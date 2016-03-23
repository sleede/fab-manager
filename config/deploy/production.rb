server "fablab.lacasemate.fr", :web, :app, :db, primary: true

set :domain, "fablab.lacasemate.fr"
set :application, "fablab"
set :user, "sleede"
set :port, 22
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@git.sleede.com:clients/fablab.git"
set :scm_user, "jarod022"
set :branch, "master"

set :rails_env, 'production'