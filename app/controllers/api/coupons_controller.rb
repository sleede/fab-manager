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
    else
      if !current_user.is_admin?
        _user_id = current_user.id
      else
        _user_id = params[:user_id]
      end

      status = @coupon.status(_user_id)
      if status != 'active'
        render json: {status: status}, status: :unprocessable_entity
      else
        render :validate, status: :ok, location: @coupon
      end
    end
  end

  def update
    authorize Coupon
    if @coupon.update(coupon_editable_params)
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

  def send_to
    authorize Coupon

    @coupon = Coupon.find_by_code(params[:coupon_code])
      if @coupon.nil?
        render json: {error: "no coupon with code #{params[:coupon_code]}"}, status: :not_found
      else
        if @coupon.send_to(params[:user_id])
          render :show, status: :ok, location: @coupon
        else
          render json: @coupon.errors, status: :unprocessable_entity
        end
      end
  end

  private
  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:name, :code, :percent_off, :validity_per_user, :valid_until, :max_usages, :active)
  end

  def coupon_editable_params
    params.require(:coupon).permit(:name, :active)
  end
end
