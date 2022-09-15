# frozen_string_literal: true

# API Controller for resources of type Order
# Orders are used in store
class API::OrdersController < API::ApiController
  before_action :authenticate_user!
  before_action :set_order, only: %i[show update destroy]

  def index
    @result = ::Orders::OrderService.list(params, current_user)
  end

  def show; end

  def update
    authorize @order

    @order = ::Orders::OrderService.update_state(@order, current_user, order_params[:state], order_params[:note])
    render :show
  end

  def destroy
    authorize @order
    @order.destroy
    head :no_content
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:state, :note)
  end
end
