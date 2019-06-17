# frozen_string_literal: true

# Send an email to all users (with role member) in the database to alert them about a privacy policy change
class NotifyPrivacyUpdateWorker
  include Sidekiq::Worker

  def perform(setting_id)
    setting = Setting.find(setting_id)

    # notify all users
    NotificationCenter.call type: :notify_privacy_policy_changed,
                            receiver: User.with_role(:member).all,
                            attached_object: setting
  end

end
