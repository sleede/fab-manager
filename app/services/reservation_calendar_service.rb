# frozen_string_literal: true

# Service class for generating iCalendar files for reservations by type
class ReservationCalendarService
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
      reservation.grouped_slots.each do |_date, daily_groups|
        daily_groups.each do |start_time, group_slots|
          cal.event do |e|
            e.dtstart     = start_time
            e.dtend       = group_slots.last[:end_at]
            e.summary     = reservation.reservable.name
            e.description = user_name(reservation)
            e.uid         = "#{reservable_type}-#{reservation.reservable.id}-#{start_time.to_i}@fabmanager"
            e.status      = group_slots.first.slots_reservations.pluck(&:canceled_at).include?(nil) ? 'IN-PROCESS' : 'CANCELLED'
          end
        end
      end
    end
  end

  def training_icalendar_event(cal)
    reservations_grouped = load_reservations.group_by(&:reservable_id)
    reservations_grouped.each_value do |reservations|
      reservation = reservations.first
      cal.event do |e|
        e.dtstart     = reservation.slots.first.start_at
        e.dtend       = reservation.slots.last.end_at
        e.summary     = reservation.reservable.name
        e.description = reservations.map { |r| user_name(r) }.join('\n')
        e.uid         = "#{reservable_type}-#{reservation.reservable_id}-#{reservation.slots.first.start_at.to_i}@fabmanager"
        e.status      = reservation.slots_reservations.first.canceled_at ? 'CANCELLED' : 'IN-PROCESS'
      end
    end
  end

  def event_icalendar_event(cal)
    reservations_grouped = load_reservations.group_by(&:reservable_id)
    reservations_grouped.each_value do |reservations|
      reservation = reservations.first
      cal.event do |e|
        e.dtstart     = reservation.slots.first.start_at
        e.dtend       = reservation.slots.last.end_at
        e.summary     = reservation.reservable.title
        e.description = build_event_description(reservations)
        e.uid         = "#{reservable_type}-#{reservation.reservable_id}-#{reservation.slots.first.start_at.to_i}@fabmanager"
        e.status      = reservation.slots_reservations.first.canceled_at ? 'CANCELLED' : 'IN-PROCESS'
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
