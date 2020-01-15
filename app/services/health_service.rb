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
    !ActiveRecord::Migrator.needs_migration?
  end

  def self.stats
    enable = Setting.find_by(name: 'fab_analytics')&.value
    return false if enable == 'false'

    require 'version'
    require 'openssl'
    require 'base64'

    stats = {
      version: Version.current,
      members: User.members.count,
      admins: User.admins.count,
      availabilities: last_week_availabilities,
      reservations: last_week_new_reservations,
      plans: !Rails.application.secrets.fablab_without_plans,
      spaces: !Rails.application.secrets.fablab_without_spaces,
      online_payment: !Rails.application.secrets.fablab_without_online_payments,
      invoices: !Rails.application.secrets.fablab_without_invoices,
      openlab: Rails.application.secrets.openlab_app_secret.present?
    }.to_json.to_s

    key = Setting.find_by(name: 'hub_public_key')&.value
    return false unless key

    public_key = OpenSSL::PKey::RSA.new(key)
    Base64.encode64(public_key.public_encrypt(stats))
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

