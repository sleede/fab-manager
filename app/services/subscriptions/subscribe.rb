class Subscribe
  attr_accessor :payment_method, :user_id

  def initialize(payment_method, user_id)
    @payment_method = payment_method
    @user_id = user_id
  end

  def pay_and_save(subscription, coupon, invoice)
    subscription.user_id = user_id
    if payment_method == :local
      subscription.save_with_local_payment(invoice, coupon)
    elsif payment_method == :stripe
      subscription.save_with_payment(invoice, coupon)
    end
  end
end
