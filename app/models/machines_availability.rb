# frozen_string_literal: true

# MachinesAvailability is the relation table between a Machine and an Availability.
# It defines periods in the agenda, when the given machine can be reserved by members.
class MachinesAvailability < ApplicationRecord
  belongs_to :machine
  belongs_to :availability
  after_destroy :cleanup_availability

  # when the MachinesAvailability is deleted (from Machine destroy cascade), we delete the corresponding
  # availability if the deleted machine was the last of this availability slot, and the availability is not
  # currently being destroyed.
  def cleanup_availability
    return if availability.destroying

    return unless availability.machines_availabilities.empty?

    availability.safe_destroy
  end
end
