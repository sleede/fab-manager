# frozen_string_literal: true

# Provides methods for update total of cart
class Cart::UpdateTotalService
  def call(order)
    total = 0
    order.order_items.each do |item|
      total += (item.amount * item.quantity) unless item.is_offered
    end
    order.total = total
    order.save
    order
  end
end
