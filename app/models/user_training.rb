class UserTraining < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :user
  belongs_to :training

  after_commit :notify_user_training_valid, on: :create

  private
  def notify_user_training_valid
    NotificationCenter.call type: 'notify_user_training_valid',
                            receiver: user,
                            attached_object: self
  end
end
