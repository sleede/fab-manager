# frozen_string_literal: true

# SlotsReservation is the relation table between a Slot and a Reservation.
class SlotsReservation < ApplicationRecord
  belongs_to :slot
  belongs_to :reservation
  after_destroy :cleanup_slots

  # when the SlotsReservation is deleted (from Reservation destroy cascade), we delete the
  # corresponding slot
  def cleanup_slots
    return unless slot.destroying

    slot.destroy
  end
end
