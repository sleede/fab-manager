# frozen_string_literal: true

# Pundit Additional context to validate the price of a local payment
class LocalPaymentContext
  attr_reader :shopping_cart, :price

  def initialize(shopping_cart, price)
    @shopping_cart = shopping_cart
    @price = price
  end

  def policy_class
    LocalPaymentPolicy
  end
end
