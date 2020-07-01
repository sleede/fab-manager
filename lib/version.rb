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
    hub_version = Setting.get('hub_last_version')
    return unless hub_version

    json = JSON.parse(hub_version)
    json['up_to_date']
  end

  # retrieve the last published version from the hub and save it into the database
  def self.check
    return if (Rails.env.development? || Rails.env.test?) && ENV['FORCE_VERSION_CHECK'] != 'true'

    # check the version
    VersionCheckWorker.perform_async
  end
end
