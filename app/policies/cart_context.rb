# frozen_string_literal: true

# Pundit Additional context for authorizing a product offering
class CartContext
  attr_reader :customer_id, :is_offered

  def initialize(customer_id, is_offered)
    @customer_id = customer_id
    @is_offered = is_offered
  end

  def policy_class
    CartPolicy
  end
end
