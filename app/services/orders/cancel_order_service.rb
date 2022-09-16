# frozen_string_literal: true

# Provides methods for cancel an order
class Orders::CancelOrderService
  def call(order, current_user)
    raise ::UpdateOrderStateError if %w[cart payment_failed canceled refunded].include?(order.state)

    order.state = 'canceled'
    ActiveRecord::Base.transaction do
      activity = order.order_activities.create(activity_type: 'canceled', operator_profile_id: current_user.invoicing_profile.id)
      order.order_items.each do |item|
        ProductService.update_stock(item.orderable, 'external', 'cancelled_by_customer', item.quantity, item.id)
      end
      order.save
      NotificationCenter.call type: 'notify_user_order_is_canceled',
                              receiver: order.statistic_profile.user,
                              attached_object: activity
    end
    order.reload
  end
end
