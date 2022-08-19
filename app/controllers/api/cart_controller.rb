# frozen_string_literal: true

# API Controller for manage user's cart
class API::CartController < API::ApiController
  before_action :current_order
  before_action :ensure_order, except: %i[create]

  def create
    authorize :cart, :create?
    @order = current_order if current_order.present?
    @order ||= Cart::CreateService.new.call(current_user)
    render 'api/orders/show'
  end

  def add_item
    authorize @current_order, policy_class: CartPolicy
    @order = Cart::AddItemService.new.call(@current_order, orderable, cart_params[:quantity])
    render 'api/orders/show'
  end

  def remove_item
    authorize :cart, policy_class: CartPolicy
    @order = Cart::RemoveItemService.new.call(@current_order, orderable)
    render 'api/orders/show'
  end

  def set_quantity
    authorize :cart, policy_class: CartPolicy
    @order = Cart::SetQuantityService.new.call(@current_order, orderable, cart_params[:quantity])
    render 'api/orders/show'
  end

  private

  def order_token
    request.headers['X-Fablab-Order-Token'] || cart_params[:order_token]
  end

  def current_order
    @current_order = Order.find_by(token: order_token)
  end

  def ensure_order
    raise ActiveRecord::RecordNotFound if @current_order.nil?
  end

  def orderable
    Product.find(cart_params[:orderable_id])
  end

  def cart_params
    params.permit(:order_token, :orderable_id, :quantity)
  end
end
