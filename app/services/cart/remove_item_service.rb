# frozen_string_literal: true

# Provides methods for remove order item to cart
class Cart::RemoveItemService
  def call(order, orderable)
    item = order.order_items.find_by(orderable_type: orderable.class.name, orderable_id: orderable.id)

    raise ActiveRecord::RecordNotFound if item.nil?

    ActiveRecord::Base.transaction do
      item.destroy!
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end
end
