# frozen_string_literal: true

# Various methods to check the application status
class HealthService
  def self.database?
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection

    ActiveRecord::Base.connected?
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def self.redis?
    !!Sidekiq.redis(&:info) # rubocop:disable Style/DoubleNegation
  rescue Redis::CannotConnectError
    false
  end

  def self.elasticsearch?
    require 'elasticsearch/transport'

    client = Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200"
    response = client.perform_request 'GET', '_cluster/health'
    !!response.body # rubocop:disable Style/DoubleNegation
  rescue Elasticsearch::Transport::Transport::Error
    false
  end

  def self.stats
    # TODO
    '651ad6a5z1daz65d1az65d156d1fz16'
  end
end

