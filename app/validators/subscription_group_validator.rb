# frozen_string_literal: true

# Check that the current subscription's plan matches the subscribing user's plan
class SubscriptionGroupValidator < ActiveModel::Validator
  def validate(record)
    return if record.statistic_profile&.group_id == record.plan&.group_id

    record.errors.add(:plan_id, "This plan is not compatible with the current user's group")
  end
end
