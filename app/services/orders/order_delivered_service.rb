# frozen_string_literal: true

# Provides methods for set order to delivered state
class Orders::OrderDeliveredService
  def call(order, current_user)
    raise ::UpdateOrderStateError if %w[cart payment_failed canceled refunded delivered].include?(order.state)

    order.state = 'delivered'
    order.order_activities.push(OrderActivity.new(activity_type: 'delivered', operator_profile_id: current_user.invoicing_profile.id))
    order.save
    order.reload
  end
end
