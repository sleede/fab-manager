class Abuse < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :signaled, polymorphic: true

  after_create :notify_admins_abuse_reported

  validates :first_name, :last_name, :email, :message, :presence => true


  private
  def notify_admins_abuse_reported
    NotificationCenter.call type: 'notify_admin_abuse_reported',
                            receiver: User.admins,
                            attached_object: self
  end
end
