require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
#require "active_model/railtie"
#require "active_record/railtie"
#require "action_controller/railtie"
#require "action_mailer/railtie"
#require "action_view/railtie"
#require "sprockets/railtie"
#require "rails/test_unit/railtie"
require 'csv'
require "rails/all"
require 'elasticsearch/rails/instrumentation'
require 'elasticsearch/persistence/model'


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fablab
  class Application < Rails::Application
    require 'fab_manager'
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = Rails.application.secrets.time_zone

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    #
    # /!\ ALL locales SHOULD be configured accordingly with this locale. /!\
    #
    config.i18n.default_locale = Rails.application.secrets.rails_locale

    config.assets.paths << Rails.root.join('vendor', 'assets', 'components').to_s

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.to_prepare do
      Devise::Mailer.layout "notifications_mailer"
    end

    # allow use rails helpers in angular templates
    Rails.application.assets.context_class.class_eval do
      include ActionView::Helpers
      include Rails.application.routes.url_helpers
    end

    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.orm :active_record
    end

    if Rails.env.development?
      config.web_console.whitelisted_ips << '192.168.0.0/16'
      config.web_console.whitelisted_ips << '192.168.99.0/16' #docker
      config.web_console.whitelisted_ips << '10.0.2.2' #vagrant
    end

    # load locales for subdirectories
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**/*.yml').to_s]

    # enable the app to find locales in plugins locales directory
    config.i18n.load_path += Dir["#{Rails.root}/plugins/*/config/locales/*.yml"]

    # enable the app to find views in plugins views directory
    Dir["#{Rails.root}/plugins/*/views"].each do |path|
      Rails.application.config.paths['app/views'] << path
    end

    FabManager.activate_plugins!

    config.after_initialize do
      if plugins = FabManager.plugins
        plugins.each { |plugin| plugin.notify_after_initialize }
      end
    end
  end
end
