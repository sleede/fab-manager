# frozen_string_literal: true

# Abuse is a report made by a visitor (not especially a logged user) who has signaled a content that seems abusive to his eyes.
# It is currently used with projects.
class Abuse < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :signaled, polymorphic: true

  after_create :notify_admins_abuse_reported

  validates :first_name, :last_name, :email, :message, presence: true


  private

  def notify_admins_abuse_reported
    NotificationCenter.call type: 'notify_admin_abuse_reported',
                            receiver: User.admins,
                            attached_object: self
  end
end
