# frozen_string_literal: true

# Provides methods for check cart's items (available, price, stock, quantity_min)
class Cart::CheckCartService
  def call(order)
    res = { order_id: order.id, details: [] }
    order.order_items.each do |item|
      errors = []
      errors.push({ error: 'is_active', value: false }) unless item.orderable.is_active
      if item.quantity > item.orderable.stock['external'] || item.orderable.stock['external'] < item.orderable.quantity_min
        value = item.orderable.stock['external'] < item.orderable.quantity_min ? 0 : item.orderable.stock['external']
        errors.push({ error: 'stock', value: value })
      end
      orderable_amount = item.orderable.amount || 0
      errors.push({ error: 'amount', value: orderable_amount / 100.0 }) if item.amount != orderable_amount
      errors.push({ error: 'quantity_min', value: item.orderable.quantity_min }) if item.quantity < item.orderable.quantity_min
      res[:details].push({ item_id: item.id, errors: errors })
    end
    res
  end
end
