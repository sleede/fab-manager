# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Used by rails 5.2 to reduce the app boot time by over 50%
gem 'bootsnap'
# Use Puma as web server
gem 'puma', '6.1.0'
gem 'shakapacker', '6.6.0'

# rails 6 compatibility with ruby 3 (may not be required after upgrade to rails 7)
gem 'matrix'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jbuilder_cache_multi'
gem 'json', '>= 2.3.0'
gem 'jsonpath'

gem 'forgery'
gem 'responders', '~> 3.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # comment over to use visual debugger (eg. RubyMine), uncomment to use manual debugging
  # gem 'byebug'
  gem 'dotenv-rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'active_record_query_trace'
  gem 'awesome_print'
  gem 'bullet'
  gem 'coveralls_reborn', '~> 0.18.0', require: false
  gem 'foreman'
  gem 'web-console', '>= 4.2.0'
  # Preview mail in the browser
  gem 'listen', '~> 3.0.5'
  gem 'overcommit'
  gem 'pry'
  gem 'rb-readline'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'railroady'
  gem 'rubocop', '~> 1.31', require: false
  gem 'rubocop-rails', require: false
  gem 'spring', '~> 4'
  gem 'spring-watcher-listen', '~> 2.1.0'
end

group :test do
  gem 'database_cleaner'
  gem 'faker'
  gem 'minitest-reporters'
  gem 'rubyXL'
  gem 'vcr', '~> 6.1.0'
  gem 'webmock'
end

gem 'seed_dump'

gem 'pg'
gem 'pg_search'

# authentication
gem 'devise', '>= 4.9'
gem 'omniauth', '~> 2.1'
gem 'omniauth-oauth2'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

gem 'rolify'

# pagination
gem 'kaminari'

# Image processing ruby wrapper for ImageMagick
gem 'mini_magick'
# upload files
gem 'carrierwave'

# slug url
gem 'friendly_id', '~> 5.1.0'

# state machine
gem 'aasm'

# Background job processing
gem 'sidekiq', '>= 6.0.7'
# Recurring jobs for Sidekiq
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs', '~> 7.1.23'

gem 'stripe', '5.29.0'

gem 'recurrence'

# PDF
gem 'pdf-reader'
gem 'prawn'
gem 'prawn-table'

gem 'elasticsearch-model', '~> 5'
gem 'elasticsearch-persistence', '~> 5'
gem 'elasticsearch-rails', '~> 5'
gem 'faraday', '~> 0.17'

gem 'pundit'

gem 'oj'

gem 'chroma'

gem 'message_format'

gem 'openlab_ruby'

gem 'api-pagination'
gem 'apipie-rails'

# XLS files generation
gem 'caxlsx'
gem 'caxlsx_rails'
gem 'rubyzip', '>= 1.3.0'

# get free disk space
gem 'sys-filesystem'

gem 'sha3'

gem 'repost'

gem 'icalendar'

gem 'tzinfo-data'

# compilation of dynamic stylesheets (home page & theme)
gem 'sassc', '= 2.4.0'

gem 'redis-session-store'

gem 'acts_as_list'

# Error reporting
gem 'sentry-rails'
gem 'sentry-ruby'
