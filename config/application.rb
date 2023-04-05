# frozen_string_literal: true

require_relative 'boot'

require 'csv'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
# require 'action_cable/engine'
require 'rails/test_unit/railtie'
# require 'sprockets/railtie'
require 'elasticsearch/rails/instrumentation'
require 'elasticsearch/persistence/model'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# module declaration
module FabManager; end

# Fab-Manager is the FabLab management solution. It provides a comprehensive, web-based, open-source tool to simplify your
# administrative tasks and your marker's projects.
class FabManager::Application < Rails::Application
  require 'fab_manager'

  # Initialize configuration defaults for originally generated Rails version.
  config.load_defaults 7.0
  config.active_support.cache_format_version = 6.1
  config.active_record.verify_foreign_keys_for_fixtures = false
  # prevent this new behavior with rails >= 5.0
  # see https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#active-record-belongs-to-required-by-default-option
  config.active_record.belongs_to_required_by_default = false
  config.active_record.schema_format = :sql

  config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  config.time_zone = Rails.application.secrets.time_zone

  config.to_prepare do
    Devise::Mailer.layout 'notifications_mailer'
  end

  config.active_job.queue_adapter = :sidekiq

  config.generators do |g|
    g.orm :active_record
    g.test_framework :mini_test
  end

  # load locales for subdirectories
  config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.yml').to_s]

  # enable the app to find locales in plugins locales directory
  config.i18n.load_path += Dir[Rails.root.join('plugins/*/config/locales/*.yml').to_s]

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # enable the app to find views in plugins views directory
  Dir[Rails.root.join('plugins/*/views').to_s].each do |path|
    Rails.application.config.paths['app/views'] << path
  end

  # disable ANSI color escape codes in active_record if NO_COLOR is defined.
  config.colorize_logging = ENV['NO_COLOR'] ? false : true

  require 'provider_config'
  config.auth_provider = ProviderConfig.new

  FabManager.activate_plugins!

  config.action_view.sanitized_allowed_tags = %w[a acronym hr pre table b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p
                                                 image iframe style]

  config.after_initialize do
    plugins = FabManager.plugins
    plugins&.each(&:notify_after_initialize)

    require 'version'
    Version.check
  end
end
