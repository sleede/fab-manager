# frozen_string_literal: true

# module definition
module Cart; end

# Provides methods for set offer to item in cart
class Cart::SetOfferService
  def call(order, orderable, is_offered)
    item = order.order_items.find_by(orderable_type: orderable.class.name, orderable_id: orderable.id)

    raise ActiveRecord::RecordNotFound if item.nil?

    item.is_offered = is_offered
    ActiveRecord::Base.transaction do
      item.save
      Cart::UpdateTotalService.new.call(order)
      order.save
    end
    order.reload
  end
end
