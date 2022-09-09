# frozen_string_literal: true

# Provides methods for set offer to item in cart
class Cart::SetOfferService
  def call(order, orderable, is_offered)
    item = order.order_items.find_by(orderable: orderable)

    raise ActiveRecord::RecordNotFound if item.nil?

    if !item.is_offered && is_offered
      order.total -= (item.amount * item.quantity)
    elsif item.is_offered && !is_offered
      order.total += (item.amount * item.quantity)
    end
    item.is_offered = is_offered
    ActiveRecord::Base.transaction do
      item.save
      order.save
    end
    order.reload
  end
end
