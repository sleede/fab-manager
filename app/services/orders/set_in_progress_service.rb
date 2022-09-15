# frozen_string_literal: true

# Provides methods for set in progress state to order
class Orders::SetInProgressService
  def call(order, current_user)
    raise ::UpdateOrderStateError if %w[cart payment_failed in_progress canceled refunded].include?(order.state)

    order.state = 'in_progress'
    order.order_activities.push(OrderActivity.new(activity_type: 'in_progress', operator_profile_id: current_user.invoicing_profile.id))
    order.save
    order.reload
  end
end
