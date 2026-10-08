# frozen_string_literal: true

# PayZen payments gateway
module PayZen; end

API_PATH = '/api-payment/V4'

# Client for connecting to the PayZen REST API
class PayZen::Client
  require 'set'

  APPROVED_HOSTS = %w[
    api.payzen.eu
    api.lyra.com
    api.payzen.com.br
    api.payzen.lat
    api.payzen.cl
    api.payzen.co
    api.payzen.de
    api.payzen.in
    api.payzen.mx
    api.secure.osb.pf
  ].to_set.freeze

  def self.valid_url?(url)
    return false if url.blank?

    uri = URI.parse(url.to_s)
    return false unless uri.is_a?(URI::HTTPS)
    return false unless uri.port == 443 || uri.port.nil?
    return false if uri.host.blank?
    return false unless APPROVED_HOSTS.include?(uri.host.downcase)
    return false unless uri.path.blank? || uri.path == '/'
    return false if uri.query.present? || uri.fragment.present?

    true
  rescue URI::InvalidURIError
    false
  end

  def initialize(base_url: nil, username: nil, password: nil)
    @base_url = base_url
    @username = username
    @password = password
  end

  protected

  def post(rel_url, payload)
    require 'uri'
    require 'net/http'
    require 'json'

    target_base_url = base_url
    raise ::PayzenError, 'Invalid or untrusted PayZen endpoint' unless self.class.valid_url?(target_base_url)

    uri = URI(File.join(target_base_url, API_PATH, rel_url))
    headers = {
      'Authorization' => authorization_header,
      'Content-Type' => 'application/json'
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 5
    http.read_timeout = 5

    req = Net::HTTP::Post.new(uri.request_uri, headers)
    req.body = payload.to_json

    res = http.request(req)
    raise ::PayzenError unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    raise ::PayzenError, json['answer'] if json['status'] == 'ERROR'

    json
  end

  def base_url
    @base_url || Setting.get('payzen_endpoint')
  end

  def authorization_header
    username, password = if @base_url.present?
                           [@username, @password]
                         else
                           [@username || Setting.get('payzen_username'), @password || Setting.get('payzen_password')]
                         end

    raise ::PayzenError, 'Missing PayZen credentials' if username.blank? || password.blank?

    credentials = Base64.strict_encode64("#{username}:#{password}")
    "Basic #{credentials}"
  end
end
