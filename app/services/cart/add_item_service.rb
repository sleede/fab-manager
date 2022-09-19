# frozen_string_literal: true

# Provides methods for add order item to cart
class Cart::AddItemService
  def call(order, orderable, quantity = 1)
    return order if quantity.to_i.zero?

    raise Cart::InactiveProductError unless orderable.is_active

    item = order.order_items.find_by(orderable: orderable)
    quantity = orderable.quantity_min > quantity.to_i && item.nil? ? orderable.quantity_min : quantity.to_i

    if item.nil?
      item = order.order_items.new(quantity: quantity, orderable: orderable, amount: orderable.amount || 0)
    else
      item.quantity += quantity.to_i
    end
    raise Cart::OutStockError if item.quantity > orderable.stock['external']

    order.total += (item.amount * quantity.to_i)
    ActiveRecord::Base.transaction do
      item.save
      order.save
    end
    order.reload
  end
end
