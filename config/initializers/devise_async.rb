Devise::Async.setup do |config|
  config.enabled = true
  config.backend = :sidekiq
  config.queue   = :devise_mailer
end