# frozen_string_literal: true

# API Controller for resources of type Reservation
# Reservations are used for Training, Machine, Space and Event
class API::ReservationsController < API::APIController
  before_action :authenticate_user!
  before_action :set_reservation, only: %i[show update]
  respond_to :json

  def index
    if params[:user_id]
      params[:user_id] = current_user.id unless current_user.admin? || current_user.manager?

      where_clause = { statistic_profile_id: StatisticProfile.find_by!(user_id: params[:user_id]) }
      where_clause[:reservable_type] = params[:reservable_type] if params[:reservable_type]
      where_clause[:reservable_id] = params[:reservable_id] if params[:reservable_id]

      @reservations = Reservation.where(where_clause)
    elsif params[:reservable_id] && params[:reservable_type] && (current_user.admin? || current_user.manager?)
      @reservations = Reservation.where(params.permit(:reservable_id, :reservable_type))
    else
      @reservations = []
    end
  end

  def show; end

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
    params.require(:reservation).permit(:message, :reservable_id, :reservable_type, :nb_reserve_places,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_reservations_attributes: %i[id slot_id offered])
  end
end
