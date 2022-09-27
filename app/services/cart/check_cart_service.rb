# frozen_string_literal: true

# Provides methods for check cart's items (available, price, stock, quantity_min)
class Cart::CheckCartService
  def call(order)
    res = { order_id: order.id, details: [] }
    order.order_items.each do |item|
      errors = []
      errors.push({ error: 'is_active', value: false }) unless item.orderable.is_active
      errors.push({ error: 'stock', value: item.orderable.stock['external'] }) if item.quantity > item.orderable.stock['external']
      orderable_amount = item.orderable.amount || 0
      errors.push({ error: 'amount', value: orderable_amount / 100.0 }) if item.amount != orderable_amount
      errors.push({ error: 'quantity_min', value: item.orderable.quantity_min }) if item.quantity < item.orderable.quantity_min
      res[:details].push({ item_id: item.id, errors: errors })
    end
    res
  end
end
