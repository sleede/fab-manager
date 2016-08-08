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

  def validate
    @coupon = Coupon.find_by_code(params[:code])
    if @coupon.nil?
      render json: {status: 'rejected'}, status: :not_found
    elsif not @coupon.active?
      render json: {status: 'disabled'}, status: :unauthorized
    elsif @coupon.valid_until.is < DateTime.now
      render json: {status: 'expired'}, status: :unauthorized
    elsif @coupon.max_usages >= @coupon.invoices.size
      render json: {status: 'sold_out'}, status: :unauthorized
    else
      render :validate, status: :ok, location: @coupon
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
    if @coupon.safe_destroy
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  private
  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:name, :code, :percent_off, :validity_per_user, :valid_until, :max_usages, :active)
  end
end
