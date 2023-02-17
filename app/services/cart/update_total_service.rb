# frozen_string_literal: true

# Provides methods for update total of cart
class Cart::UpdateTotalService
  # @param order[Order]
  def call(order)
    total = 0
    order.order_items.each do |item|
      update_item_price(item)
      total += (item.amount * item.quantity) unless item.is_offered
    end
    order.total = total
    order.save
    order
  end

  private

  # @param item[OrderItem]
  def update_item_price(item)
    return unless item.orderable_type.match(/^CartItem::/)

    item.update(amount: item.orderable.price[:amount] || 0)
  end
end
