# frozen_string_literal: true

# Provides methods for add order item to cart
class Cart::AddItemService
  def call(order, orderable, quantity = 1)
    return order if quantity.to_i.zero?

    raise Cart::InactiveProductError unless orderable.is_active

    raise Cart::OutStockError if quantity > orderable.stock['external']

    item = order.order_items.find_by(orderable: orderable)
    if item.nil?
      item = order.order_items.new(quantity: quantity, orderable: orderable, amount: orderable.amount)
    else
      item.quantity += quantity.to_i
    end
    order.total += (orderable.amount * quantity.to_i)
    ActiveRecord::Base.transaction do
      item.save
      order.save
    end
    order.reload
  end
end
