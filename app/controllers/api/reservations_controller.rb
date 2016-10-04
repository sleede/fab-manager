class API::ReservationsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:show, :update]
  respond_to :json

  def index
    if params[:reservable_id] and params[:reservable_type] and params[:user_id]
      if !current_user.is_admin?
        params[:user_id] = current_user.id
      end
      @reservations = Reservation.where(params.permit(:reservable_id, :reservable_type, :user_id))
    elsif params[:reservable_id] and params[:reservable_type] and current_user.is_admin?
      @reservations = Reservation.where(params.permit(:reservable_id, :reservable_type))
    else
      @reservations = []
    end
  end

  def show
  end

  def create
    begin
      if current_user.is_admin?
        @reservation = Reservation.new(reservation_params)
        is_reserve = @reservation.save_with_local_payment(coupon_params[:coupon_code])
      else
        @reservation = Reservation.new(reservation_params.merge(user_id: current_user.id))
        is_reserve = @reservation.save_with_payment(coupon_params[:coupon_code])
      end
      if is_reserve
        SubscriptionExtensionAfterReservation.new(@reservation).extend_subscription_if_eligible

        render :show, status: :created, location: @reservation
      else
        render json: @reservation.errors, status: :unprocessable_entity
      end
    rescue InvalidCouponError
      render json: {coupon_code: 'wrong coupon code or expired'}, status:  :unprocessable_entity
    end
  end

  def update
    authorize @reservation
    if @reservation.update(reservation_params)
      render :show, status: :ok, location: @reservation
    else
      render json: @reservation.errors, status: :unprocessable_entity
    end
  end

  private
  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:user_id, :message, :reservable_id, :reservable_type, :card_token, :plan_id,
                                        :nb_reserve_places,
                                        tickets_attributes: [:event_price_category_id, :booked],
                                        slots_attributes: [:id, :start_at, :end_at, :availability_id, :offered])
  end

  def coupon_params
    params.permit(:coupon_code)
  end
end
