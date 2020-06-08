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

  def self.migrations?
    !ActiveRecord::Base.connection.migration_context.needs_migration?
  end

  def self.row_stats
    require 'version'
    {
      version: Version.current,
      members: User.members.count,
      admins: User.admins.count,
      availabilities: last_week_availabilities,
      reservations: last_week_new_reservations,
      plans: Setting.get('plans_module'),
      spaces: Setting.get('spaces_module'),
      online_payment: !Rails.application.secrets.fablab_without_online_payments,
      invoices: Setting.get('invoicing_module'),
      openlab: Setting.get('openlab_app_secret').present?
    }
  end

  def self.stats
    enable = Setting.get('fab_analytics')
    return false if enable == 'false'

    require 'openssl'
    require 'base64'

    row_stats.to_json.to_s

    key = Setting.get('hub_public_key')
    return false unless key

    public_key = OpenSSL::PKey::RSA.new(key)
    Base64.encode64(public_key.public_encrypt(row_stats.to_json.to_s))
  end

  # availabilities for the last week
  def self.last_week_availabilities
    Availability.where('start_at >= ? AND end_at <= ?', DateTime.current - 7.days, DateTime.current).count
  end

  # reservations made during the last week
  def self.last_week_new_reservations
    Reservation.where('created_at >= ? AND created_at < ?', DateTime.current - 7.days, DateTime.current).count
  end
end

