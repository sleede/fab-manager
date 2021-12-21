# frozen_string_literal: true

# API Controller for resources of type Price
# Prices are used in reservations (Machine, Space)
class API::PricesController < API::ApiController
  before_action :authenticate_user!

  def create
    @price = Price.new(price_params)
    @price.amount *= 100

    authorize @price

    if @price.save
      render json: @price, status: :created
    else
      render json: @price.errors, status: :unprocessable_entity
    end
  end

  def index
    @prices = PriceService.list(params)
  end

  def update
    authorize Price
    @price = Price.find(params[:id])
    price_parameters = price_params
    price_parameters[:amount] = price_parameters[:amount] * 100
    if @price.update(price_parameters)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def compute
    cs = CartService.new(current_user)
    cart = cs.from_hash(params)
    @amount = cart.total
  end

  private

  def price_create_params
    params.require(:price).permit(:amount, :duration, :group_id, :plan_id, :priceable_id, :priceable_type)
  end

  def price_params
    params.require(:price).permit(:amount, :duration)
  end
end
