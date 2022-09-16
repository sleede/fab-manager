# frozen_string_literal: true

# Provides methods for refund an order
class Orders::OrderRefundedService
  def call(order, current_user)
    raise ::UpdateOrderStateError if %w[cart payment_error refunded delivered].include?(order.state)

    order.state = 'refunded'
    ActiveRecord::Base.transaction do
      activity = order.order_activities.create(activity_type: 'refunded', operator_profile_id: current_user.invoicing_profile.id)
      order.save
      NotificationCenter.call type: 'notify_user_order_is_refunded',
                              receiver: order.statistic_profile.user,
                              attached_object: activity
    end
    order.reload
  end
end
