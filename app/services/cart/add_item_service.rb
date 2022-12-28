# frozen_string_literal: true

# Provides methods for add order item to cart
class Cart::AddItemService
  def call(order, orderable, quantity = 1)
    return order if quantity.to_i.zero?

    item = case orderable
           when Product
             add_product(order, orderable, quantity)
           when Slot
             add_slot(order, orderable)
           else
             raise Cart::UnknownItemError
           end

    order.created_at = Time.current if order.order_items.length.zero?

    ActiveRecord::Base.transaction do
      item.save
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end

  private

  def add_product(order, orderable, quantity)
    raise Cart::InactiveProductError unless orderable.is_active

    item = order.order_items.find_by(orderable: orderable)
    quantity = orderable.quantity_min > quantity.to_i && item.nil? ? orderable.quantity_min : quantity.to_i

    if item.nil?
      item = order.order_items.new(quantity: quantity, orderable: orderable, amount: orderable.amount || 0)
    else
      item.quantity += quantity
    end
    raise Cart::OutStockError if item.quantity > orderable.stock['external']

    item
  end

  def add_slot(order, orderable)
    item = order.order_items.find_by(orderable: orderable)

    item = order.order_items.new(quantity: 1, orderable: orderable, amount: orderable.amount || 0) if item.nil?

    item
  end
end
