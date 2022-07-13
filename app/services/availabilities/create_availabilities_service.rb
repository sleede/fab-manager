# frozen_string_literal: true

# Provides helper methods to create an Availability with multiple occurrences
class Availabilities::CreateAvailabilitiesService
  def create(availability, occurrences = [])
    availability.update_attributes(occurrence_id: availability.id)
    slot_duration = availability.slot_duration || Setting.get('slot_duration').to_i

    occurrences.each do |o|
      start_at = Time.zone.parse(o[:start_at])
      end_at = Time.zone.parse(o[:end_at])

      avail = if availability.start_at == start_at && availability.end_at == end_at
                availability
              else
                Availability.create!(
                  start_at: start_at,
                  end_at: end_at,
                  available_type: availability.available_type,
                  is_recurrent: availability.is_recurrent,
                  period: availability.period,
                  nb_periods: availability.nb_periods,
                  end_date: availability.end_date,
                  occurrence_id: availability.occurrence_id,
                  machine_ids: availability.machine_ids,
                  training_ids: availability.training_ids,
                  space_ids: availability.space_ids,
                  tag_ids: availability.tag_ids,
                  nb_total_places: availability.nb_total_places,
                  slot_duration: availability.slot_duration,
                  plan_ids: availability.plan_ids
                )
              end

      ((end_at - start_at) / slot_duration.minutes).to_i.times do |i|
        Slot.new(
          start_at: start_at + (i * slot_duration).minutes,
          end_at: start_at + (i * slot_duration).minutes + slot_duration.minutes,
          availability_id: avail.id
        ).save!
      end
    end
  end
end
