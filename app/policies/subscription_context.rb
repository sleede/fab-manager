# frozen_string_literal: true

# Pundit Additional context to validate the price of a subscription
class SubscriptionContext
  attr_reader :subscription, :price

  def initialize(subscription, price)
    @subscription = subscription
    @price = price
  end

  def policy_class
    SubscriptionPolicy
  end
end
