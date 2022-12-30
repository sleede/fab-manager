# frozen_string_literal: true

# module definition
module Cart; end

# Provides methods to update the customer of the given cart
class Cart::SetCustomerService
  def initialize(operator)
    @operator = operator
  end

  def call(order, customer)
    return order unless @operator.privileged?

    return order unless order.operator_profile_id.blank? || order.operator_profile_id == @operator.invoicing_profile.id

    return order unless order.state == 'cart'

    ActiveRecord::Base.transaction do
      order.statistic_profile_id = customer.statistic_profile.id
      order.operator_profile_id = @operator.invoicing_profile.id
      unset_offer(order, customer)
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end

  # If the operator is also the customer, he cannot offer items to himself, so we unset all the offers
  def unset_offer(order, customer)
    return unless @operator == customer

    order.order_items.each do |item|
      item.is_offered = false
      item.save
    end
  end
end
