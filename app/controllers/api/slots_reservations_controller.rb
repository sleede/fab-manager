# frozen_string_literal: true

# API Controller for resources of type Slot
# Slots are used to cut Availabilities into reservable slots. The duration of these slots is configured per
# availability by Availability.slot_duration, or otherwise globally by Setting.get('slot_duration')
class API::SlotsReservationsController < API::APIController
  before_action :authenticate_user!
  before_action :set_slots_reservation, only: %i[update cancel]
  respond_to :json

  def update
    authorize @slot_reservation
    if @slot_reservation.update(slot_params)
      Subscriptions::ExtensionAfterReservation.new(@slot_reservation.reservation).extend_subscription_if_eligible
      render :show, status: :ok, location: @slot_reservation
    else
      render json: @slot_reservation.errors, status: :unprocessable_entity
    end
  end

  def cancel
    authorize @slot_reservation
    SlotsReservationsService.cancel(@slot_reservation)
  end

  private

  def set_slots_reservation
    @slot_reservation = SlotsReservation.find(params[:id])
  end

  def slot_params
    params.require(:slots_reservation).permit(:slot_id)
  end
end
