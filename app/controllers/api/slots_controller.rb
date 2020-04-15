# frozen_string_literal: true

# API Controller for resources of type Slot
# Slots are used to cut Availabilities into reservable slots. The duration of these slots is configured per
# availability by Availability.slot_duration, or otherwise globally by ApplicationHelper::SLOT_DURATION minutes
class API::SlotsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_slot, only: %i[update cancel]
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
    SlotService.new.cancel(@slot)
  end

  private

  def set_slot
    @slot = Slot.find(params[:id])
  end

  def slot_params
    params.require(:slot).permit(:start_at, :end_at, :availability_id)
  end
end
