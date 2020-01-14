# frozen_string_literal: true

# Fab-Manager central hub (remote host)
class FabHub
  def self.version_check_payload
    {
      origin: "#{Rails.application.secrets.default_protocol}://#{Rails.application.secrets.default_host}",
      version: Version.current,
      lang: I18n.default_locale.to_s
    }
  end

  def self.fab_manager_version_check
    get('/api/versions/check', version_check_payload)
  end

  def self.get(rel_url, payload)
    require 'uri'
    require 'net/http'
    require 'json'

    uri = URI.join(hub_base_url, rel_url)
    uri.query = URI.encode_www_form(payload)

    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  end

  def self.hub_base_url
    if Rails.env.production?
      ENV['HUB_BASE_URL'] || 'https://hub.fab-manager.com'
    else
      ENV['HUB_BASE_URL'] || 'http://localhost:3000'
    end
  end
end
