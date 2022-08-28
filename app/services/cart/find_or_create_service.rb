# frozen_string_literal: true

# Provides methods for find or create a cart
class Cart::FindOrCreateService
  def call(order_token, user)
    order = Order.find_by(token: order_token, state: 'cart')

    if order && user && ((user.member? && order.statistic_profile_id.present? && order.statistic_profile_id != user.statistic_profile.id) ||
        (user.privileged? && order.operator_profile_id.present? && order.operator_profile_id != user.invoicing_profile.id))
      order = nil
    end
    order = nil if order && !user && order.statistic_profile_id.present?
    if order && order.statistic_profile_id.present? && Order.where(statistic_profile_id: order.statistic_profile_id,
                                                                   payment_state: 'paid').where('created_at > ?', order.created_at).last.present?
      order = nil
    end

    if order.nil?
      if user&.member?
        last_paid_order = Order.where(statistic_profile_id: user.statistic_profile.id,
                                      payment_state: 'paid').last
        order = if last_paid_order
                  Order.where(statistic_profile_id: user.statistic_profile.id,
                              state: 'cart').where('created_at > ?', last_paid_order.created_at).last
                else
                  Order.where(statistic_profile_id: user.statistic_profile.id, state: 'cart').last
                end
      end
      if user&.privileged?
        last_paid_order = Order.where(operator_profile_id: user.invoicing_profile.id,
                                      payment_state: 'paid').last
        order = if last_paid_order
                  Order.where(operator_profile_id: user.invoicing_profile.id,
                              state: 'cart').where('created_at > ?', last_paid_order.created_at).last
                else
                  Order.where(operator_profile_id: user.invoicing_profile.id, state: 'cart').last
                end
      end
    end

    if order
      order.update(statistic_profile_id: user.statistic_profile.id) if order.statistic_profile_id.nil? && user&.member?
      order.update(operator_profile_id: user.invoicing_profile.id) if order.operator_profile_id.nil? && user&.privileged?
      return order
    end

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
