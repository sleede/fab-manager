# frozen_string_literal: true

# API Controller for resources of type Reservation
# Reservations are used for Training, Machine, Space and Event
class API::ReservationsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_reservation, only: %i[show update]
  respond_to :json

  def index
    if params[:reservable_id] && params[:reservable_type] && params[:user_id]
      params[:user_id] = current_user.id unless current_user.admin? || current_user.manager?

      where_clause = params.permit(:reservable_id, :reservable_type).to_h
      where_clause[:statistic_profile_id] = StatisticProfile.find_by!(user_id: params[:user_id])

      @reservations = Reservation.where(where_clause)
    elsif params[:reservable_id] && params[:reservable_type] && (current_user.admin? || current_user.manager?)
      @reservations = Reservation.where(params.permit(:reservable_id, :reservable_type))
    else
      @reservations = []
    end
  end

  def show; end

  # Admins can create any reservations. Members can directly create reservations if total = 0,
  # otherwise, they must use payments_controller#confirm_payment.
  # Managers can create reservations for other users
  def create
    user_id = current_user.admin? || current_user.manager? ? params[:reservation][:user_id] : current_user.id
    price = transaction_amount(current_user.admin? || (current_user.manager? && current_user.id != user_id), user_id)

    authorize ReservationContext.new(Reservation, price[:amount], user_id)

    @reservation = Reservation.new(reservation_params)
    is_reserve = Reservations::Reserve.new(user_id, current_user.invoicing_profile.id)
                                      .pay_and_save(@reservation, payment_details: price[:price_details])

    if is_reserve
      SubscriptionExtensionAfterReservation.new(@reservation).extend_subscription_if_eligible

      render :show, status: :created, location: @reservation
    else
      render json: @reservation.errors, status: :unprocessable_entity
    end
  rescue InvalidCouponError
    render json: { coupon_code: 'wrong coupon code or expired' }, status: :unprocessable_entity
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

  def transaction_amount(is_admin, user_id)
    user = User.find(user_id)
    price_details = Price.compute(is_admin,
                                  user,
                                  reservation_params[:reservable_type].constantize.find(reservation_params[:reservable_id]),
                                  reservation_params[:slots_attributes] || [],
                                  plan_id: reservation_params[:plan_id],
                                  nb_places: reservation_params[:nb_reserve_places],
                                  tickets: reservation_params[:tickets_attributes],
                                  coupon_code: coupon_params[:coupon_code])

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(user, total)

    { price_details: price_details, amount: (total - wallet_debit) }
  end

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:message, :reservable_id, :reservable_type, :plan_id, :nb_reserve_places,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def coupon_params
    params.permit(:coupon_code)
  end
end
