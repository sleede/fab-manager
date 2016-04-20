Openlab.configure do |config|
  config.app_secret = Rails.application.secrets.openfablab_app_secret
  config.base_uri = Rails.env.production? ? "https://urltochange.nawak" : "localhost:3300/api/v1"
end
