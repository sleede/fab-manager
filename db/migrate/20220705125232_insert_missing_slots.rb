# frozen_string_literal: true

# Previously, only the reserved slots were saved in DB, other slots were created on the fly.
# Now we save all slots in DB, so we must re-create slots for the existing availabilities
class InsertMissingSlots < ActiveRecord::Migration[5.2]
  def up
    Availability.where(available_type: %w[machines space]).each do |availability|
      slot_duration = availability.slot_duration || Setting.get('slot_duration').to_i

      ((availability.end_at - availability.start_at) / slot_duration.minutes).to_i.times do |i|
        Slot.find_or_create_by(
          start_at: availability.start_at + (i * slot_duration).minutes,
          end_at: availability.start_at + (i * slot_duration).minutes + slot_duration.minutes,
          availability_id: availability.id
        )
      end
    end

    Availability.where(available_type: %w[training event]).each do |availability|
      Slot.find_or_create_by(
        start_at: availability.start_at,
        end_at: availability.end_at,
        availability_id: availability.id
      )
    end
  end

  def down
    Slot.where.not(id: SlotsReservation.all.map(&:slot_id)).each(&:destroy)
  end
end
