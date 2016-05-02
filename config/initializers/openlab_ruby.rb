Openlab.configure do |config|
  config.app_secret = Rails.application.secrets.openlab_app_secret
  config.base_uri = Rails.application.secrets.openlab_base_uri
end
