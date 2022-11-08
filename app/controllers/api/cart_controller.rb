# frozen_string_literal: true

# API Controller for manage user's cart
class API::CartController < API::ApiController
  include API::OrderConcern

  before_action :current_order, except: %i[create]
  before_action :ensure_order, except: %i[create]

  def create
    authorize :cart, :create?
    @order ||= Cart::FindOrCreateService.new(current_user).call(order_token)
    render 'api/orders/show'
  end

  def add_item
    authorize @current_order, policy_class: CartPolicy
    @order = Cart::AddItemService.new.call(@current_order, orderable, cart_params[:quantity])
    render 'api/orders/show'
  end

  def remove_item
    authorize @current_order, policy_class: CartPolicy
    @order = Cart::RemoveItemService.new.call(@current_order, orderable)
    render 'api/orders/show'
  end

  def set_quantity
    authorize @current_order, policy_class: CartPolicy
    @order = Cart::SetQuantityService.new.call(@current_order, orderable, cart_params[:quantity])
    render 'api/orders/show'
  end

  def set_offer
    authorize CartContext.new(params[:customer_id], cart_params[:is_offered])
    @order = Cart::SetOfferService.new.call(@current_order, orderable, cart_params[:is_offered])
    render 'api/orders/show'
  end

  def refresh_item
    authorize @current_order, policy_class: CartPolicy
    @order = Cart::RefreshItemService.new.call(@current_order, orderable)
    render 'api/orders/show'
  end

  def validate
    authorize @current_order, policy_class: CartPolicy
    @order_errors = Cart::CheckCartService.new.call(@current_order)
    render json: @order_errors
  end

  private

  def orderable
    Product.find(cart_params[:orderable_id])
  end
end
