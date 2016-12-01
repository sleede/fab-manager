source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5'
# Use SCSS for stylesheets
gem 'sass-rails', '5.0.1'
gem 'compass-rails', '2.0.4'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', '= 0.12.0', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jbuilder_cache_multi'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc #TODO remove unused ?

gem 'forgery'
gem 'responders', '~> 2.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # comment over to use visual debugger (eg. RubyMine), uncomment to use manual debugging
  # gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'railroady'
end

group :development do
  # Preview mail in the browser
  gem 'letter_opener'
  gem 'awesome_print'

  gem "puma"
  gem 'foreman'

  gem 'capistrano'
  gem 'rvm-capistrano', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano-maintenance', '0.0.5', require: false

  gem 'active_record_query_trace'

  gem 'coveralls', require: false
end

group :test do
  gem 'database_cleaner'
  gem 'faker'
  gem 'test_after_commit'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'vcr'
  gem 'byebug'
  gem 'pdf-reader'
end

group :production do
  gem 'unicorn'
  gem 'rails_12factor'
end

gem 'seed_dump'

gem 'pg'

gem 'devise'
gem 'devise-async'

gem 'omniauth'
gem 'omniauth-oauth2'

gem 'rolify'

gem 'kaminari'

gem 'figaro'

gem 'bootstrap-sass'
gem 'font-awesome-rails'

#using bower instead
#gem 'angularjs-rails'

# Image processing ruby wrapper for ImageMagick
gem 'mini_magick'
# upload files
gem 'carrierwave'

gem 'twitter'
gem 'twitter-text'

# slug url
gem 'friendly_id', '~> 5.1.0'

# state machine
gem 'aasm'

# Background job processing
gem 'sidekiq'
gem 'sinatra', require: false
# Recurring jobs for Sidekiq
gem 'sidekiq-cron'

gem 'stripe', '1.30.2'

gem 'recurrence'

# PDF
gem 'prawn'
gem 'prawn-table'

gem 'elasticsearch-rails'
gem 'elasticsearch-model'
gem 'elasticsearch-persistence'

gem 'notify_with'

gem 'pundit'

gem 'oj'

gem 'actionpack-page_caching'
gem 'rails-observers'

gem 'chroma'


gem 'protected_attributes'

gem 'message_format'

gem 'openlab_ruby'

gem 'api-pagination'
gem 'has_secure_token'
gem 'apipie-rails'

# XLS files generation
gem 'rubyzip', '~> 1.1.0'
gem 'axlsx', '2.1.0.pre'
gem 'axlsx_rails'
