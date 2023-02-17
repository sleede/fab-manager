# frozen_string_literal: true

# Provides methods for refresh amount of order item
class Cart::RefreshItemService
  def call(order, orderable)
    raise Cart::InactiveProductError unless orderable.is_active

    item = order.order_items.find_by(orderable_type: orderable.class.name, orderable_id: orderable.id)

    raise ActiveRecord::RecordNotFound if item.nil?

    item.amount = orderable.amount || 0
    ActiveRecord::Base.transaction do
      item.save
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end
end
