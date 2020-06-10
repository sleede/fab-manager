# frozen_string_literal: true

# Provides helper methods for public calendar of Availability
class Availabilities::PublicAvailabilitiesService
  def initialize(current_user)
    @current_user = current_user
    @service = Availabilities::StatusService.new('public')
  end

  # provides a list of slots and availabilities for the machines, between the given dates
  def machines(start_date, end_date, reservations, machine_ids)
    availabilities = Availability.includes(:tags, :machines)
                                 .where(available_type: 'machines')
                                 .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                 .where(lock: false)
    slots = []
    availabilities.each do |a|
      slot_duration = a.slot_duration || Setting.get('slot_duration').to_i
      a.machines.each do |machine|
        next unless machine_ids&.include?(machine.id.to_s)

        ((a.end_at - a.start_at) / slot_duration.minutes).to_i.times do |i|
          slot = Slot.new(
            start_at: a.start_at + (i * slot_duration).minutes,
            end_at: a.start_at + (i * slot_duration).minutes + slot_duration.minutes,
            availability_id: a.id,
            availability: a,
            machine: machine,
            title: machine.name
          )
          slot = @service.machine_reserved_status(slot, reservations, @current_user)
          slots << slot
        end
      end
    end
    { availabilities: availabilities, slots: slots }
  end

  # provides a list of slots and availabilities for the spaces, between the given dates
  def spaces(start_date, end_date, reservations, available_id)
    availabilities = Availability.includes(:tags, :spaces).where(available_type: 'space')
                                 .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                 .where(lock: false)

    availabilities.where(available_id: available_id) if available_id

    slots = []
    availabilities.each do |a|
      slot_duration = a.slot_duration || Setting.get('slot_duration').to_i
      space = a.spaces.first
      ((a.end_at - a.start_at) / slot_duration.minutes).to_i.times do |i|
        next unless (a.start_at + (i * slot_duration).minutes) > DateTime.current

        slot = Slot.new(
          start_at: a.start_at + (i * slot_duration).minutes,
          end_at: a.start_at + (i * slot_duration).minutes + slot_duration.minutes,
          availability_id: a.id,
          availability: a,
          space: space,
          title: space.name
        )
        slot = @service.space_reserved_status(slot, reservations, @current_user)
        slots << slot
      end
    end
    { availabilities: availabilities, slots: slots }
  end

  def public_availabilities(start_date, end_date, reservations, ids)
    if in_same_day(start_date, end_date)
      # request for 1 single day

      # trainings, events
      training_event_availabilities = Availability.includes(:tags, :trainings, :slots)
                                                  .where(available_type: %w[training event])
                                                  .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                                  .where(lock: false)
      # machines
      machines_avail = machines(start_date, end_date, reservations, ids[:machines])
      machine_slots = machines_avail[:slots]
      # spaces
      spaces_avail = spaces(start_date, end_date, reservations, ids[:spaces])
      space_slots = spaces_avail[:slots]

      [].concat(training_event_availabilities).concat(machine_slots).concat(space_slots)
    else
      # request for many days (week or month)
      avails = Availability.includes(:tags, :machines, :trainings, :spaces, :event, :slots)
                           .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                           .where(lock: false)
      avails.each do |a|
        if a.available_type == 'training' || a.available_type == 'event'
          a = @service.training_event_reserved_status(a, reservations, @current_user)
        elsif a.available_type == 'space'
          a.is_reserved = @service.reserved_availability?(a, @current_user)
        end
      end
      avails
    end
  end

  private

  def in_same_day(start_date, end_date)
    (end_date.to_date - start_date.to_date).to_i == 1
  end
end
