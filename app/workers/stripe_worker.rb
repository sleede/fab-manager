class StripeWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :stripe

  def perform(action, *params)
    send(action, *params)
  end

  def create_stripe_customer(user_id)
    user = User.find(user_id)
    customer = Stripe::Customer.create(
      description: user.profile.full_name,
      email: user.email
    )
    user.update_columns(stp_customer_id: customer.id)
  end
end
