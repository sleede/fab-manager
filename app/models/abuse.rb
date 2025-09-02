# frozen_string_literal: true

# Abuse is a report made by a visitor (not especially a logged user) who has signaled a content that seems abusive to his eyes.
# It is currently used with projects.
class Abuse < ApplicationRecord
  include NotificationAttachedObject

  belongs_to :signaled, polymorphic: true

  after_create :notify_admins_abuse_reported

  validates :first_name, :last_name, :email, :message, presence: true
  validates :signaled_type, inclusion: { in: ['Project'], message: 'must be allowed type' }
  validates :signaled_id, presence: true
  validate :signaled_exists

  private

  def signaled_exists
    case signaled_type
    when 'Project'
      errors.add(:signaled_id, 'Project does not exist') unless Project.exists?(signaled_id)
    else
      errors.add(:signaled_type, 'Type does not allow')
    end
  end

  def notify_admins_abuse_reported
    NotificationCenter.call type: 'notify_admin_abuse_reported',
                            receiver: User.admins,
                            attached_object: self
  end
end
