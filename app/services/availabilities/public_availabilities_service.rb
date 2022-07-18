# frozen_string_literal: true

# Provides helper methods for public calendar of Availability
class Availabilities::PublicAvailabilitiesService
  def initialize(current_user)
    @current_user = current_user
    @service = Availabilities::StatusService.new('public')
  end

  # provides a list of slots and availabilities for the machines, between the given dates
  def machines(window, machine_ids, level)
    machine_ids = [] if machine_ids.nil?
    service = Availabilities::AvailabilitiesService.new(@current_user, level)
    slots = []
    machine_ids.each do |machine_id|
      machine = Machine.friendly.find(machine_id)
      slots.concat(service.machines(machine, @current_user, window))
    end
    slots
  end

  # provides a list of slots and availabilities for the spaces, between the given dates
  def spaces(window, spaces_ids, level)
    spaces_ids = [] if spaces_ids.nil?
    service = Availabilities::AvailabilitiesService.new(@current_user, level)
    slots = []
    spaces_ids.each do |space_id|
      space = Space.friendly.find(space_id)
      slots.concat(service.spaces(space, @current_user, window))
    end
    slots
  end

  def public_availabilities(window, ids, events = false)
    level = in_same_day(window[:start], window[:end]) ? 'slot' : 'availability'
    service = Availabilities::AvailabilitiesService.new(@current_user, level)

    machines_slots = machines(window, ids[:machines], level)
    spaces_slots = spaces(window, ids[:spaces], level)
    trainings_slots = service.trainings(Training.where(id: ids[:trainings]), @current_user, window)
    events_slots = events ? service.events(Event.all, @current_user, window) : []

    [].concat(trainings_slots).concat(events_slots).concat(machines_slots).concat(spaces_slots)
  end

  private

  def in_same_day(start_date, end_date)
    (end_date.to_date - start_date.to_date).to_i == 1
  end
end
