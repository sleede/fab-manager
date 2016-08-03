class API::CouponsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_coupon, only: [:show, :update, :destroy]

  def index
    @coupons = Coupon.all
  end

  def show
  end

  def create
    authorize Coupon
    @coupon = Coupon.new(coupon_params)
    if @coupon.save
      render :show, status: :created, location: @coupon
    else
      render json: @coupon.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Coupon
    if @coupon.update(coupon_params)
      render :show, status: :ok, location: @coupon
    else
      render json: @coupon.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Coupon
    @coupon.destroy
    head :no_content
  end

  private
  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:name, :code, :percent_off, :valid_until, :max_usages, :active)
  end
end
