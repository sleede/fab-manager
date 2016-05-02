class API::SlotsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_slot, only: [:update, :cancel]
  respond_to :json

  def update
    authorize @slot
    if @slot.update(slot_params)
      SubscriptionExtensionAfterReservation.new(@slot.reservation).extend_subscription_if_eligible
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
end
