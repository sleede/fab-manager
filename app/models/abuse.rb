class Abuse < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :signaled, polymorphic: true

  after_create :notify_admins_abuse_reported


  private
  def notify_admins_abuse_reported
    NotificationCenter.call type: 'notify_admin_abuse_reported',
                            receiver: User.admins,
                            attached_object: self
  end
end
