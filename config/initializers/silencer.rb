require 'silencer/rails/logger'

silenced_actions = []
silenced_actions << "/api/notifications/polling" unless Rails.application.secrets.enable_notifications_polling_logging

Rails.application.configure do
  config.middleware.swap(
    Rails::Rack::Logger,
    Silencer::Logger,
    config.log_tags,
    silence: silenced_actions
  )
end