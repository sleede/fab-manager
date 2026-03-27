# frozen_string_literal: true

require 'asaas'
require 'json'
require 'net/http'
require 'uri'
require 'asaas/error'

# Client for connecting to the Asaas REST API
class Asaas::Client
  def initialize(api_key: nil, environment: nil)
    @api_key = api_key
    @environment = environment
  end

  def get(path)
    request(Net::HTTP::Get.new(uri(path)))
  end

  def post(path, payload = {})
    req = Net::HTTP::Post.new(uri(path))
    req.body = payload.to_json
    request(req)
  end

  def put(path, payload = {})
    req = Net::HTTP::Put.new(uri(path))
    req.body = payload.to_json
    request(req)
  end

  protected

  def request(req)
    req['access_token'] = api_key
    req['Content-Type'] = 'application/json'
    req['Accept'] = 'application/json'

    response = Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: req.uri.scheme == 'https') do |http|
      http.request(req)
    end

    body = response.body.presence || '{}'
    json = JSON.parse(body)

    return json if response.is_a?(Net::HTTPSuccess)

    raise AsaasError, extract_error(json, response)
  rescue JSON::ParserError
    raise AsaasError, 'Invalid response from Asaas'
  end

  def extract_error(json, response)
    errors = json['errors'] || []
    return errors.pluck('description').compact.join(', ') if errors.any?

    json['message'].presence || response.message
  end

  def uri(path)
    URI("#{base_url}#{path}")
  end

  def base_url
    environment == 'production' ? 'https://api.asaas.com' : 'https://api-sandbox.asaas.com'
  end

  def api_key
    @api_key || Setting.get('asaas_api_key')
  end

  def environment
    @environment || Setting.get('asaas_environment') || 'sandbox'
  end
end
