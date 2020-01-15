# frozen_string_literal: true

# retrieve the current Fab-manager version
class Version
  def self.current
    package = File.read('package.json')
    JSON.parse(package)['version']
  end

  def self.up_to_date?
    hub_version = Setting.find_by(name: 'hub_last_version')&.value
    return unless hub_version

    json = JSON.parse(hub_version)
    json['up_to_date']
  end

  def self.check_and_schedule
    return if (Rails.env.development? || Rails.env.test?) && ENV['FORCE_VERSION_CHECK'] != 'true'

    VersionCheckWorker.perform_async
    # every sunday at 1:15am
    m = DateTime.current.minute
    h = DateTime.current.hour
    d = DateTime.current.cwday
    Sidekiq::Cron::Job.create(name: 'Automatic version check', cron: "#{m} #{h} * * #{d}", class: 'VersionCheckWorker')
  end
end
