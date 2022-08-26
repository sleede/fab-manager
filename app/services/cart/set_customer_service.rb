# frozen_string_literal: true

# Provides methods for admin set customer to order
class Cart::SetCustomerService
  def call(order, user_id)
    user = User.find(user_id)
    order.update(statistic_profile_id: user.statistic_profile.id)
    order.reload
  end
end
