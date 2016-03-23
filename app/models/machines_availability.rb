class MachinesAvailability < ActiveRecord::Base
  belongs_to :machine
  belongs_to :availability
  after_destroy :cleanup_availability

  # when the MachinesAvailability is deleted (from Machine destroy cascade), we delete the corresponding
  # availability if the deleted machine was the last is this availability slot and teh availability is not
  # currently being destroyed.
  def cleanup_availability
    unless availability.destroying
      if availability.machines_availabilities.size == 0
        availability.safe_destroy
      end
    end
  end
end
