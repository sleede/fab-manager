# frozen_string_literal: true

require 'uri'

# Server-only official client, built and verified on first use instead of at Rails boot.
# Asset compilation, SQL migrations and pages unrelated to statistics must not depend on
# Elasticsearch reachability; every search operation still refuses a non-9 server.
class SearchIndex::Connection
  class Unavailable < StandardError; end

  LOCK = Mutex.new

  class << self
    def client
      @client || LOCK.synchronize { @client ||= verified(build) }
    end

    def reset!
      LOCK.synchronize { @client = nil }
    end

    private

    def build
      url = ENV.fetch('ELASTICSEARCH_URL') { "https://#{Rails.application.secrets.elaticsearch_host}:9200" }
      origin = URI.parse(url)
      valid_origin = origin.is_a?(URI::HTTPS) && origin.host.present? && origin.userinfo.nil? &&
                     origin.query.nil? && origin.fragment.nil? && ['', '/'].include?(origin.path)
      raise Unavailable, 'ELASTICSEARCH_URL must be a fixed HTTPS origin without embedded credentials' unless valid_origin

      Elasticsearch::Client.new(**options(url))
    rescue URI::InvalidURIError, SystemCallError => e
      raise Unavailable, "Elasticsearch configuration unavailable: #{e.class}"
    end

    def options(url)
      ssl = { verify: true }
      ssl[:ca_file] = ENV.fetch('ELASTICSEARCH_CA_FILE') if ENV.fetch('ELASTICSEARCH_CA_FILE', nil).present?
      result = { url: url, log: false, transport_options: { ssl: ssl, request: { timeout: 30, open_timeout: 5 } } }
      result[:user] = ENV.fetch('ELASTICSEARCH_USERNAME') if ENV.fetch('ELASTICSEARCH_USERNAME', nil).present?
      password = secret('ELASTICSEARCH_PASSWORD')
      api_key = secret('ELASTICSEARCH_API_KEY')
      raise Unavailable, 'Choose either password or API key authentication' if password && api_key

      result[:password] = password if password
      result[:api_key] = api_key if api_key
      result
    end

    # File-backed credentials survive container replacement.
    def secret(name)
      value = ENV.fetch(name, nil).presence
      file = ENV.fetch("#{name}_FILE", nil).presence
      raise Unavailable, "Configure only #{name} or #{name}_FILE" if value && file

      file ? File.read(file).strip : value
    end

    def verified(client)
      version = client.info.dig('version', 'number')
      raise Unavailable, 'Elasticsearch 9 required; migrate the ES5 installation before using this code' unless version&.start_with?('9.')

      client
    end
  end
end
