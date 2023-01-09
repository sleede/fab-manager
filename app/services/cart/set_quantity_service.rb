# frozen_string_literal: true

# Provides methods for update quantity of order item
class Cart::SetQuantityService
  def call(order, orderable, quantity = nil)
    return order if quantity.to_i.zero?

    quantity = orderable.quantity_min > quantity.to_i ? orderable.quantity_min : quantity.to_i

    raise Cart::OutStockError if quantity.to_i > orderable.stock['external']

    item = order.order_items.find_by(orderable_type: orderable.class.name, orderable_id: orderable.id)

    raise ActiveRecord::RecordNotFound if item.nil?

    ActiveRecord::Base.transaction do
      item.update(quantity: quantity.to_i)
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end
end
