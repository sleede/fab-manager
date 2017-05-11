class SlotsReservation < ActiveRecord::Base
  belongs_to :slot
  belongs_to :reservation
  after_destroy :cleanup_slots

  # when the SlotsReservation is deleted (from Reservation destroy cascade), we delete the
  # corresponding slot
  def cleanup_slots
    unless slot.destroying
      slot.destroy
    end
  end
end
