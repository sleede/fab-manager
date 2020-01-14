# frozen_string_literal: true

# Will check the application version to ensure it is up-to-date
class VersionCheckWorker
  include Sidekiq::Worker

  def perform
    require 'fab_hub'
    res = FabHub.fab_manager_version_check

    setting_ver = Setting.find_or_initialize_by(name: 'hub_last_version')
    setting_ver.value = { version: res['last_version']['semver'], security: res['last_version']['security'], status: res['up_to_date'] }.to_json.to_s
    setting_ver.save!

    setting_key = Setting.find_or_initialize_by(name: 'hub_public_key')
    setting_key.value = res['key']
    setting_key.save!
  end
end
