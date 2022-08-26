# frozen_string_literal: true

# Provides methods for create cart
class Cart::CreateService
  def call(user)
    token = GenerateTokenService.new.call(Order)
    order_param = {
      token: token,
      state: 'cart',
      total: 0
    }
    if user
      order_param[:statistic_profile_id] = user.statistic_profile.id if user.member?

      order_param[:operator_profile_id] = user.invoicing_profile.id if user.privileged?
    end
    Order.create!(order_param)
  end
end
