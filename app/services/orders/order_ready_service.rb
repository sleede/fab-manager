# frozen_string_literal: true

# Provides methods for set order to ready state
class Orders::OrderReadyService
  def call(order, current_user, note = '')
    raise ::UpdateOrderStateError if %w[cart payment_failed ready canceled refunded].include?(order.state)

    order.state = 'ready'
    ActiveRecord::Base.transaction do
      activity = order.order_activities.create(activity_type: 'ready', operator_profile_id: current_user.invoicing_profile.id, note: note)
      order.save
      NotificationCenter.call type: 'notify_user_order_is_ready',
                              receiver: order.statistic_profile.user,
                              attached_object: activity
    end
    order.reload
  end
end
