# frozen_string_literal: true

Apipie.configure do |config|
  config.app_name                = 'Fab-manager'
  config.api_base_url            = '/open_api'
  config.doc_base_url            = '/open_api/doc'
  # where is your API defined?
  config.api_controllers_matcher = Rails.root.join('app/controllers/open_api/v1/*.rb')
  config.validate = false
  config.translate = false
  config.default_locale = nil
  config.app_info['v1'] = <<-RDOC
    = Pagination
    ---
    You can ask for pagination on your requests, by providing the GET parameters *page* and *per_page* (when it's available).
    The meta-data about pagination will be returned in the headers, following RFC-5988 standard for web linking.
    It uses headers *Link*, *Total* and *Per-Page*.

    = Authentication
    ---
    Authentication is done using *Authorization* header.
    You just have to set header *Authorization* to <tt>Token token=YOUR_TOKEN</tt> for every request.

    = Json
    ---
    Depending on your client, you may have to set header <tt>Accept: application/json</tt> for every request,
    otherwise some clients may request *html* by default which will result in error.

    = Amounts
    ---
    Everywhere in the OpenAPI amounts are reported in cents. For exemple, if you get <tt>{ "amount" : 1000 }</tt>,
    from the OpenAPI, this means that the price is 10 € (or whatever your currency is).
  RDOC
end
