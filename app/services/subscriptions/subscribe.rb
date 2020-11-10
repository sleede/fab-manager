# frozen_string_literal: true

# Provides helper methods for Subscription actions
class Subscriptions::Subscribe
  attr_accessor :user_id, :operator_profile_id

  def initialize(operator_profile_id, user_id = nil)
    @user_id = user_id
    @operator_profile_id = operator_profile_id
  end

  def pay_and_save(subscription, coupon: nil, invoice: nil, payment_intent_id: nil, schedule: nil)
    return false if user_id.nil?

    subscription.statistic_profile_id = StatisticProfile.find_by(user_id: user_id).id
    subscription.save_with_payment(operator_profile_id, invoice, coupon, payment_intent_id, schedule)
  end

  def extend_subscription(subscription, new_expiration_date, free_days)
    return subscription.free_extend(new_expiration_date, @operator_profile_id) if free_days

    new_sub = Subscription.create(
      plan_id: subscription.plan_id,
      statistic_profile_id: subscription.statistic_profile_id,
      expiration_date: new_expiration_date
    )
    if new_sub.save
      new_sub.user.generate_subscription_invoice(operator_profile_id)
      UsersCredits::Manager.new(user: new_sub.user).reset_credits
      return new_sub
    end
    false
  end
end
