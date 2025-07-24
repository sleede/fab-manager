# frozen_string_literal: true

# Service class for generating iCalendar files for reservations by type
class ReservationCalendarService
  require 'icalendar'
  require 'icalendar/tzinfo'

  ALLOWED_TYPES = %w[Machine Training Event Space].freeze

  def initialize(params)
    @params = params
    @reservable_type = validate_reservable_type
  end

  def call
    cal = Icalendar::Calendar.new
    cal.add_timezone Time.zone.tzinfo.ical_timezone Time.zone.now
    cal.x_wr_calname = "FabManager #{reservable_type} Reservations"
    build_icalendar(cal)
  end

  private

  attr_reader :reservable_type

  def validate_reservable_type
    type = @params[:reservable_type]&.capitalize
    raise ArgumentError, "Invalid reservable type. Allowed types: #{ALLOWED_TYPES.join(', ')}" unless ALLOWED_TYPES.include?(type)

    type
  end

  def build_icalendar(cal)
    case reservable_type
    when 'Machine', 'Space'
      slot_icalendar_event(cal)
    when 'Training'
      training_icalendar_event(cal)
    when 'Event'
      event_icalendar_event(cal)
    end
    cal
  end

  def load_reservations
    Reservation.includes(:slots, :slots_reservations)
               .where(reservable_type: reservable_type)
               # .where(slots_reservations: { canceled_at: nil })
               .where('slots.start_at >= ?', Time.current)
               .order('slots.start_at')
  end

  def slot_icalendar_event(cal)
    reservations = load_reservations

    reservations.find_each do |reservation|
      reservation.slots_reservations.where(canceled_at: nil).each do |slots_reservation|
        cal.event do |e|
          e.dtstart     = slots_reservation.slot.start_at
          e.dtend       = slots_reservation.slot.end_at
          e.summary     = slots_reservation.reservation.reservable.name
          e.description = user_name(slots_reservation.reservation)
          e.uid         = "#{reservable_type}-#{slots_reservation.reservation.reservable.id}-#{slots_reservation.slot.start_at.to_i}@fabmanager"
          # e.status      = slots_reservation.canceled_at ? 'CANCELLED' : 'CONFIRMED'
        end
      end
      # reservation.grouped_slots.each do |_date, daily_groups|
      #   daily_groups.each do |start_time, group_slots|
      #     slots_not_canceled = Slot.where(id: group_slots).includes(:slots_reservations)
      #                              .where(slots_reservations: { canceled_at: nil }).order(:start_at)
      #     start_at = slots_not_canceled.present? ? slots_not_canceled.first.start_at : start_time
      #     cal.event do |e|
      #       e.dtstart     = start_at
      #       e.dtend       = slots_not_canceled.present? ? slots_not_canceled.last.end_at : group_slots.last[:end_at]
      #       e.summary     = reservation.reservable.name
      #       e.description = user_name(reservation)
      #       e.uid         = "#{reservable_type}-#{reservation.reservable.id}-#{start_at.to_i}@fabmanager"
      #       e.status      = slots_not_canceled.present? ? 'CONFIRMED' : 'CANCELLED'
      #     end
      #   end
      # end
    end
  end

  def training_icalendar_event(cal)
    reservations_grouped = load_reservations.group_by(&:reservable_id)
    reservations_grouped.each_value do |reservations|
      reservation = reservations.first
      reservations_not_canceled = Reservation.where(id: reservations).includes(:slots_reservations)
                                             .where(slots_reservations: { canceled_at: nil })
      cal.event do |e|
        e.dtstart     = reservation.slots.first.start_at
        e.dtend       = reservation.slots.last.end_at
        e.summary     = reservation.reservable.name
        e.description = reservations_not_canceled.map { |r| user_name(r) }.join('\n')
        e.uid         = "#{reservable_type}-#{reservation.reservable_id}-#{reservation.slots.first.start_at.to_i}@fabmanager"
        e.status      = reservations_not_canceled.present? ? 'CONFIRMED' : 'CANCELLED'
      end
    end
  end

  def event_icalendar_event(cal)
    reservations_grouped = load_reservations.group_by(&:reservable_id)
    reservations_grouped.each_value do |reservations|
      reservation = reservations.first
      reservations_not_canceled = Reservation.where(id: reservations).includes(:slots_reservations)
                                             .where(slots_reservations: { canceled_at: nil })
      cal.event do |e|
        e.dtstart     = reservation.slots.first.start_at
        e.dtend       = reservation.slots.last.end_at
        e.summary     = reservation.reservable.title
        e.description = build_event_description(reservations_not_canceled)
        e.uid         = "#{reservable_type}-#{reservation.reservable_id}-#{reservation.slots.first.start_at.to_i}@fabmanager"
        e.status      = reservations_not_canceled.present? ? 'CONFIRMED' : 'CANCELLED'
      end
    end
  end

  def build_event_description(reservations)
    reservations.map do |r|
      places = r.nb_reserve_places + (r.tickets.map(&:booked).reduce(:+) || 0)
      "#{user_name(r)} (#{places} places)"
    end.join('\n')
  end

  def user_name(reservation)
    reservation.user&.profile&.full_name || 'Unknown User'
  end
end
