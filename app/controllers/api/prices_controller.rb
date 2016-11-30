class API::PricesController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize Price
    @prices = Price.all
    if params[:priceable_type]
      @prices = @prices.where(priceable_type: params[:priceable_type])
      if params[:priceable_id]
        @prices = @prices.where(priceable_id: params[:priceable_id])
      end
    end
    if params[:plan_id]
      if params[:plan_id] =~ /no|nil|null|undefined/i
        plan_id = nil
      else
        plan_id = params[:plan_id]
      end
      @prices = @prices.where(plan_id: plan_id)
    end
    if params[:group_id]
      @prices = @prices.where(group_id: params[:group_id])
    end
  end

  def update
    authorize Price
    @price = Price.find(params[:id])
    _price_params = price_params
    _price_params[:amount] = _price_params[:amount] * 100
    if @price.update(_price_params)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def compute
    _price_params = compute_price_params
    # user
    _user = User.find(_price_params[:user_id])
    # reservable
    if _price_params[:reservable_id].nil?
      @amount = {elements: nil, total: 0, before_coupon: 0}
    else
      _reservable = _price_params[:reservable_type].constantize.find(_price_params[:reservable_id])
      @amount = Price.compute(current_user.is_admin?, _user, _reservable, _price_params[:slots_attributes], _price_params[:plan_id], _price_params[:nb_reserve_places], _price_params[:tickets_attributes], coupon_params[:coupon_code])
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
                                        tickets_attributes: [:event_price_category_id, :booked],
                                        slots_attributes: [:id, :start_at, :end_at, :availability_id, :offered])
  end

  def coupon_params
    params.permit(:coupon_code)
  end
end
