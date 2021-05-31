# frozen_string_literal: true

# Provides helper methods for Subscription actions
class Subscriptions::Subscribe
  attr_accessor :user_id, :operator_profile_id

  def initialize(operator_profile_id, user_id = nil)
    @user_id = user_id
    @operator_profile_id = operator_profile_id
  end

  def extend_subscription(subscription, new_expiration_date, free_days)
    return subscription.free_extend(new_expiration_date, @operator_profile_id) if free_days

    new_sub = Subscription.create(
      plan_id: subscription.plan_id,
      statistic_profile_id: subscription.statistic_profile_id,
    )
    new_sub.expiration_date = new_expiration_date
    if new_sub.save
      schedule = subscription.original_payment_schedule

      operator = InvoicingProfile.find(@operator_profile_id).user
      cs = CartService.new(operator)
      cart = cs.from_hash(customer_id: subscription.user.id,
                          items: [
                            {
                              subscription: {
                                plan_id: subscription.plan_id
                              }
                            }
                          ],
                          payment_schedule: !schedule.nil?)
      details = cart.total

      payment = if schedule
                  operator = InvoicingProfile.find(operator_profile_id)&.user

                  PaymentScheduleService.new.create(
                    [new_sub],
                    details[:before_coupon],
                    operator: operator,
                    payment_method: schedule.payment_method,
                    user: new_sub.user,
                    payment_id: schedule.gateway_payment_mean&.id,
                    payment_type: schedule.gateway_payment_mean&.class
                  )
                else
                  InvoicesService.create(
                    details,
                    operator_profile_id,
                    [new_sub],
                    new_sub.user
                  )
                end
      payment.save
      payment.post_save(schedule&.gateway_payment_mean&.id)
      UsersCredits::Manager.new(user: new_sub.user).reset_credits
      return new_sub
    end
    false
  end
end
