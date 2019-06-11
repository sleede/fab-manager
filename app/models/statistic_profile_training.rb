# frozen_string_literal: true

# Stores trainings validated per user (non validated trainings are only recorded in reservations)
class StatisticProfileTraining < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :statistic_profile
  belongs_to :training

  after_commit :notify_user_training_valid, on: :create

  private

  def notify_user_training_valid
    NotificationCenter.call type: 'notify_user_training_valid',
                            receiver: statistic_profile.user,
                            attached_object: self
  end
end
