# frozen_string_literal: true

# Provides methods for update quantity of order item
class Cart::SetQuantityService
  def call(order, orderable, quantity = nil)
    return order if quantity.to_i.zero?

    quantity = orderable.quantity_min > quantity.to_i ? orderable.quantity_min : quantity.to_i

    raise Cart::OutStockError if quantity.to_i > orderable.stock['external']

    item = order.order_items.find_by(orderable: orderable)

    raise ActiveRecord::RecordNotFound if item.nil?

    different_quantity = quantity.to_i - item.quantity
    order.total += (item.amount * different_quantity) unless item.is_offered
    ActiveRecord::Base.transaction do
      item.update(quantity: quantity.to_i)
      order.save
    end
    order.reload
  end
end
