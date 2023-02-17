# frozen_string_literal: true

# Provides a method to cancel an order
class Orders::OrderCanceledService
  def call(order, current_user)
    raise ::UpdateOrderStateError if %w[cart canceled refunded delivered].include?(order.state)

    order.state = 'canceled'
    ActiveRecord::Base.transaction do
      activity = order.order_activities.create(activity_type: 'canceled', operator_profile_id: current_user.invoicing_profile.id)
      order.save
      NotificationCenter.call type: 'notify_user_order_is_canceled',
                              receiver: order.statistic_profile.user,
                              attached_object: activity
    end
    order.reload
  end
end
