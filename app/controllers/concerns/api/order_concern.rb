# frozen_string_literal: true

# Concern for CartController and CheckoutController
module API::OrderConcern
  private

  def order_token
    request.headers['X-Fablab-Order-Token'] || cart_params[:order_token]
  end

  def current_order
    @current_order = Order.find_by(token: order_token, state: 'cart')
  end

  def ensure_order
    raise ActiveRecord::RecordNotFound if @current_order.nil?
  end

  def cart_params
    params.permit(:order_token, :orderable_id, :quantity, :user_id, :is_offered)
  end
end
