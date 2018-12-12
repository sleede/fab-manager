module Subscriptions
  class Subscribe
    attr_accessor :user_id

    def initialize(user_id)
      @user_id = user_id
    end

    def pay_and_save(subscription, payment_method, coupon, invoice)
      subscription.user_id = user_id
      if payment_method == :local
        subscription.save_with_local_payment(invoice, coupon)
      elsif payment_method == :stripe
        subscription.save_with_payment(invoice, coupon)
      end
    end

    def extend_subscription(subscription, new_expiration_date, free_days)
      return subscription.free_extend(new_expiration_date) if free_days

      new_sub = Subscription.create(
        plan_id: subscription.plan_id,
        user_id: subscription.user_id,
        expiration_date: new_expiration_date
      )
      if new_sub.save
        new_sub.user.generate_subscription_invoice
        return new_sub
      end
      false
    end
  end
end
