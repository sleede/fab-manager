# frozen_string_literal: true

# Provides methods for add order item to cart
class Cart::AddItemService
  def call(order, orderable, quantity = 1)
    return order if quantity.to_i.zero?

    item = case orderable.class.name
           when 'Product'
             add_product(order, orderable, quantity)
           when /^CartItem::/
             add_cart_item(order, orderable)
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

    item = order.order_items.find_by(orderable_type: orderable.class.name, orderable_id: orderable.id)
    quantity = orderable.quantity_min > quantity.to_i && item.nil? ? orderable.quantity_min : quantity.to_i

    if item.nil?
      item = order.order_items.new(quantity: quantity, orderable: orderable, amount: orderable.amount || 0)
    else
      item.quantity += quantity
    end
    raise Cart::OutStockError if item.quantity > orderable.stock['external']

    item
  end

  def add_cart_item(order, orderable)
    order.order_items.new(quantity: 1, orderable_type: orderable.class.name, orderable_id: orderable.id, amount: orderable.price[:amount] || 0)
  end
end
