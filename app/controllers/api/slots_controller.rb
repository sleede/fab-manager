class API::SlotsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_slot, only: [:update, :cancel]
  respond_to :json

  def update
    authorize @slot
    if @slot.update(slot_params)
      reservation_user = @slot.reservation.user
      if @slot.reservation.reservable_type == 'Training' and is_first_training_and_active_subscription(reservation_user)
        reservation_user.subscription.update_expired_date_with_first_training(@slot.start_at)
      end
      render :show, status: :created, location: @slot
    else
      render json: @slot.errors, status: :unprocessable_entity
    end
  end

  def cancel
    authorize @slot
    @slot.update_attributes(:canceled_at => DateTime.now)
  end

  private
  def set_slot
    @slot = Slot.find(params[:id])
  end

  def slot_params
    params.require(:slot).permit(:start_at, :end_at, :availability_id)
  end

  def is_first_training_and_active_subscription(user)
    user.reservations.where(reservable_type: 'Training').size == 1 and user.subscription and !user.subscription.is_expired?
  end
end
