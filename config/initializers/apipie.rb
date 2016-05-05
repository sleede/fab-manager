Apipie.configure do |config|
  config.app_name                = "Fab-manager"
  config.api_base_url            = "/open_api"
  config.doc_base_url            = "/open_api/doc"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/open_api/v1/*.rb"
  config.validate = false
  config.app_info['v1'] = <<-EOS
    = Pagination
    ---
    Pagination is done using headers. Following RFC-5988 standard for web linking.
    It uses headers *Link*, *Total* and *Per-Page*.

    = Authentification
    ---
    Authentification is done using *Authorization* header.
    You just have to set header *Authorization* to <tt>Token token=YOUR_TOKEN</tt> for every request.
  EOS
end
