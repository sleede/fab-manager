Openlab.configure do |config|
  config.base_uri = Rails.application.secrets.openlab_base_uri unless Rails.env.production?
end
