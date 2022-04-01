Openlab.configure do |config|
  config.base_uri = Rails.application.secrets.openlab_base_uri if Rails.application.secrets.openlab_base_uri
  config.httparty_verify = Rails.application.secrets.openlab_ssl_verify
  config.httparty_verify_peer = Rails.application.secrets.openlab_ssl_verify_peer
end
