class SubscriptionGroupValidator < ActiveModel::Validator
  def validate(record)
    return if record.statistic_profile.group_id == record.plan.group

    record.errors[:plan_id] << "This plan is not compatible with the current user's group"
  end
end
