# frozen_string_literal: true

# Provides methods for Order
class Orders::OrderService
  def in_stock?(order, stock_type = 'external')
    order.order_items.each do |item|
      return false if item.orderable.stock[stock_type] < item.quantity
    end
    true
  end

  def all_products_is_active?(order)
    order.order_items.each do |item|
      return false unless item.orderable.is_active
    end
    true
  end
end
