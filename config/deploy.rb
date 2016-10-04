require "bundler/capistrano"
require "rvm/capistrano"
require 'capistrano/ext/multistage'
require 'capistrano/maintenance'

set :stages, %w(production staging)
set :default_stage, "staging"


default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

# after "deploy:finalize_update", "deploy:assets:precompile"

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  desc 'Symlink bootstrap glyphicons'
  task :symlink, :roles => :web, :except => { :no_release => true } do
    #run "rm -R #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*"
    run "ln -nfs #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*.ttf #{shared_path}/assets/bootstrap/glyphicons-halflings-regular.ttf"
    run "ln -nfs #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*.svg #{shared_path}/assets/bootstrap/glyphicons-halflings-regular.svg"
    run "ln -nfs #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*.woff #{shared_path}/assets/bootstrap/glyphicons-halflings-regular.woff"
    run "ln -nfs #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*.woff2 #{shared_path}/assets/bootstrap/glyphicons-halflings-regular.woff2"
    run "ln -nfs #{shared_path}/assets/bootstrap/glyphicons-halflings-regular-*.eot #{shared_path}/assets/bootstrap/glyphicons-halflings-regular.eot"
    #run "rm -R #{shared_path}/assets/select2/select2*"
    run "ln -nfs #{shared_path}/assets/select2/select2-*.png #{shared_path}/assets/select2.png"
    run "ln -nfs #{shared_path}/assets/select2/select2x2-*.png #{shared_path}/assets/select2x2.png"
    run "ln -nfs #{shared_path}/assets/select2/select2-spinner-*.gif #{shared_path}/assets/select2-spinner.gif"
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/uploads"
    run "mkdir -p #{shared_path}/invoices"
    run "mkdir -p #{shared_path}/exports"
    run "mkdir -p #{shared_path}/plugins"
    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit #{shared_path}/config/database.yml and add your username and password"
    put File.read("config/application.yml"), "#{shared_path}/config/application.yml"
    puts "Now edit #{shared_path}/config/application.yml and add your ENV vars"

  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "rm -rf #{release_path}/config/application.yml"
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  #before "deploy", "deploy:check_revision"

  desc "load seed to bd"
  task :load_seed, :roles => :app do
    run "cd #{current_path} && bundle exec rake db:seed RAILS_ENV=production"
  end

  desc "Rake db:migrate"
  task :db_migrate, :roles => :app do
    run "cd #{current_path} && bundle exec rake db:migrate RAILS_ENV=production"
  end
  after "deploy:create_symlink", "deploy:db_migrate"

  desc "Symlinks the uploads dir"
  task :symlink_uploads_dir, :roles => :app do
    run "rm -rf #{release_path}/public/uploads"
    run "ln -nfs #{shared_path}/uploads/ #{release_path}/public/"
  end
  after "deploy:finalize_update", 'deploy:symlink_uploads_dir'

  desc "Symlinks the invoices dir"
  task :symlink_invoices_dir, :roles => :app do
    run "rm -rf #{release_path}/invoices"
    run "ln -nfs #{shared_path}/invoices/ #{release_path}/"
  end
  after "deploy:finalize_update", 'deploy:symlink_invoices_dir'

  desc "Symlinks the exports dir"
  task :symlink_exports_dir, :roles => :app do
    run "rm -rf #{release_path}/exports"
    run "ln -nfs #{shared_path}/exports/ #{release_path}/"
  end
  after "deploy:finalize_update", 'deploy:symlink_exports_dir'

  desc "Symlinks the plugins dir"
  task :symlink_plugins_dir, :roles => :app do
    run "rm -rf #{release_path}/plugins"
    run "ln -nfs #{shared_path}/plugins/ #{release_path}/"
  end
  after "deploy:finalize_update", 'deploy:symlink_plugins_dir'

  namespace :assets do
    desc 'Run the precompile task locally and rsync with shared'
    task :precompile, :roles => :web, :except => { :no_release => true } do
      %x{bundle exec rake assets:precompile RAILS_ENV=production}
      %x{rsync --recursive --times --rsh='ssh -p#{port}' --compress --human-readable --progress public/assets #{user}@#{domain}:#{shared_path}}
      %x{bundle exec rake assets:clean}
    end

  end

end
