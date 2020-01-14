# frozen_string_literal: true

# Will check the application version to ensure it is up-to-date
class VersionCheckWorker
  include Sidekiq::Worker

  def perform
    require 'fab_hub'
    res = FabHub.fab_manager_version_check

    setting_ver = Setting.find_or_initialize_by(name: 'hub_last_version')
    value = {
      security: res['status']['security'],
      up_to_date: res['status']['up_to_date']
    }
    if res['upgrade_to']
      value['version'] = res['upgrade_to']['semver']
      value['url'] = res['upgrade_to']['url']
    end
    setting_ver.value = value.to_json.to_s
    setting_ver.save!

    setting_key = Setting.find_or_initialize_by(name: 'hub_public_key')
    return if setting_key.value == res['key']

    setting_key.value = res['key']
    setting_key.save!
  end
end
