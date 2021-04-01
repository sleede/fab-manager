# frozen_string_literal: true

# PayZen payement gateway
module PayZen; end

API_PATH = '/api-payment/V4'

# Client for connecting to the PayZen REST API
class PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    @base_url = base_url
    @username = username
    @password = password
  end

  protected

  def post(rel_url, payload, tmp_base_url: nil, tmp_username: nil, tmp_password: nil)
    require 'uri'
    require 'net/http'
    require 'json'

    uri = URI.join(tmp_base_url || base_url, API_PATH, rel_url)
    headers = {
      'Authorization' => authorization_header(tmp_username, tmp_password),
      'Content-Type' => 'application/json'
    }

    res = Net::HTTP.post(uri, payload.to_json, headers)
    JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  end

  def base_url
    Setting.get('payzen_endpoint')
  end

  def authorization_header(user, passwd)
    username = user || Setting.get('payzen_username')
    password = passwd || Setting.get('payzen_password')

    credentials = Base64.strict_encode64("#{username}:#{password}")
    "Basic #{credentials}"
  end
end
