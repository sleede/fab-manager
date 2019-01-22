# frozen_string_literal: true

# API Controller for resources of type Price
# Prices are used in reservations (Machine, Space)
class API::PricesController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize Price
    @prices = Price.all
    if params[:priceable_type]
      @prices = @prices.where(priceable_type: params[:priceable_type])

      @prices = @prices.where(priceable_id: params[:priceable_id]) if params[:priceable_id]
    end
    if params[:plan_id]
      plan_id = if params[:plan_id] =~ /no|nil|null|undefined/i
                  nil
                else
                  params[:plan_id]
                end
      @prices = @prices.where(plan_id: plan_id)
    end
    @prices = @prices.where(group_id: params[:group_id]) if params[:group_id]
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
    price_parameters = compute_price_params
    # user
    user = User.find(price_parameters[:user_id])
    # reservable
    if price_parameters[:reservable_id].nil?
      @amount = {elements: nil, total: 0, before_coupon: 0}
    else
      reservable = price_parameters[:reservable_type].constantize.find(price_parameters[:reservable_id])
      @amount = Price.compute(current_user.admin?,
                              user,
                              reservable,
                              price_parameters[:slots_attributes] || [],
                              price_parameters[:plan_id],
                              price_parameters[:nb_reserve_places],
                              price_parameters[:tickets_attributes],
                              coupon_params[:coupon_code])
    end


    if @amount.nil?
      render status: :unprocessable_entity
    else
      render status: :ok
    end
  end

  private

  def price_params
    params.require(:price).permit(:amount)
  end

  def compute_price_params
    params.require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :user_id, :nb_reserve_places,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def coupon_params
    params.permit(:coupon_code)
  end
end
