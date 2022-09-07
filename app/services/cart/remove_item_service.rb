# frozen_string_literal: true

# Provides methods for remove order item to cart
class Cart::RemoveItemService
  def call(order, orderable)
    item = order.order_items.find_by(orderable: orderable)

    raise ActiveRecord::RecordNotFound if item.nil?

    order.total -= (item.amount * item.quantity.to_i)
    ActiveRecord::Base.transaction do
      item.destroy!
      order.save
    end
    order.reload
  end
end
