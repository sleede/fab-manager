# frozen_string_literal: true

# Pundit Additional context to validate the price of a subscription
class SubscriptionContext
  attr_reader :subscription, :price, :user_id

  def initialize(subscription, price, user_id)
    @subscription = subscription
    @price = price
    @user_id = user_id
  end

  def policy_class
    SubscriptionPolicy
  end
end
