class SubscriptionGroupValidator < ActiveModel::Validator
  def validate(record)
    if record.user.group != record.plan.group
      record.errors[:plan_id] << "This plan is not compatible with the current user's group"
    end
  end
end