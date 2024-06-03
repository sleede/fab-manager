# frozen_string_literal: true

# Provides helper methods for public calendar of Availability
class Availabilities::PublicAvailabilitiesService
  def initialize(current_user)
    @current_user = current_user
  end

  def public_availabilities(window, ids, events: false)
    level = in_same_day(window[:start], window[:end]) ? 'slot' : 'availability'
    service = Availabilities::AvailabilitiesService.new(@current_user, level)

    machines_slots = if Setting.get('machines_module')
                       service.machines(Machine.where(id: ids[:machines]), @current_user, window)
                     else
                       []
                     end
    spaces_slots = Setting.get('spaces_module') ? service.spaces(Space.where(id: ids[:spaces]), @current_user, window) : []
    trainings_slots = if Setting.get('trainings_module')
                        service.trainings(Training.where(id: ids[:trainings]), @current_user, window)
                      else
                        []
                      end
    events_slots = events ? service.events(Event.where(deleted_at: nil), @current_user, window) : []

    [].concat(trainings_slots).concat(events_slots).concat(machines_slots).concat(spaces_slots)
  end

  private

  def in_same_day(start_date, end_date)
    (end_date.to_date - start_date.to_date).to_i == 1
  end
end
