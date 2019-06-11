# frozen_string_literal: true

# Provides helper methods for Subscription actions
class Subscriptions::Subscribe
  attr_accessor :user_id, :operator_id

  def initialize(operator_id, user_id = nil)
    @user_id = user_id
    @operator_id = operator_id
  end

  def pay_and_save(subscription, payment_method, coupon, invoice)
    return false if user_id.nil?

    subscription.statistic_profile_id = StatisticProfile.find_by(user_id: user_id).id
    if payment_method == :local
      subscription.save_with_local_payment(operator_id, invoice, coupon)
    elsif payment_method == :stripe
      subscription.save_with_payment(operator_id, invoice, coupon)
    end
  end

  def extend_subscription(subscription, new_expiration_date, free_days)
    return subscription.free_extend(new_expiration_date, @operator_id) if free_days

    new_sub = Subscription.create(
      plan_id: subscription.plan_id,
      statistic_profile_id: subscription.statistic_profile_id,
      expiration_date: new_expiration_date
    )
    if new_sub.save
      new_sub.user.generate_subscription_invoice(operator_id)
      return new_sub
    end
    false
  end
end
