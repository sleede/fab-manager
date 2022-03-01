Openlab.configure do |config|
  config.base_uri = Rails.application.secrets.openlab_base_uri if Rails.application.secrets.openlab_base_uri
end
