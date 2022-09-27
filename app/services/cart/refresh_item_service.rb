# frozen_string_literal: true

# Provides methods for refresh amount of order item
class Cart::RefreshItemService
  def call(order, orderable)
    raise Cart::InactiveProductError unless orderable.is_active

    item = order.order_items.find_by(orderable: orderable)

    raise ActiveRecord::RecordNotFound if item.nil?

    order.total -= (item.amount * item.quantity.to_i) unless item.is_offered
    item.amount = orderable.amount || 0
    order.total += (item.amount * item.quantity.to_i) unless item.is_offered
    ActiveRecord::Base.transaction do
      item.save
      order.save
    end
    order.reload
  end
end
