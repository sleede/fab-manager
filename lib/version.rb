# frozen_string_literal: true

# retrieve the Fab-manager's versions
class Version
  # currently installed
  def self.current
    package = File.read('package.json')
    JSON.parse(package)['version']
  end

  # currently published
  def self.up_to_date?
    hub_version = Setting.find_by(name: 'hub_last_version')&.value
    return unless hub_version

    json = JSON.parse(hub_version)
    json['up_to_date']
  end

  # periodically retrieve the last published version from the hub and save it into the database
  def self.check_and_schedule
    job_name = 'Automatic version check'
    return if (Rails.env.development? || Rails.env.test?) && ENV['FORCE_VERSION_CHECK'] != 'true'

    job = Sidekiq::Cron::Job.find name: job_name
    unless job
      # schedule a version check, every week at the current day+time
      # this will prevent that all the instances query the hub simultaneously
      m = DateTime.current.minute
      h = DateTime.current.hour
      d = DateTime.current.cwday
      job = Sidekiq::Cron::Job.new(name: job_name, cron: "#{m} #{h} * * #{d}", class: 'VersionCheckWorker')
      job.save
    end
    job.enque!
  end
end
