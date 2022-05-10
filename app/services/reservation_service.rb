# frozen_string_literal: true

# Provides methods around the Reservation objects
class ReservationService
  class << self
    def build_ics(reservation)
      require 'icalendar'

      cal = Icalendar::Calendar.new
      reservation.grouped_slots.each do |date, daily_groups|
        daily_groups.each do |start_time, group_slots|
          cal.event do |e|
            e.dtstart     = start_time
            e.dtend       = group_slots.last[:end_at]
            e.summary     = I18n.t('reservation_ics.summary', TYPE: I18n.t("reservation_ics.type.#{reservation.reservable.class.name}"))
            e.description = I18n.t('reservation_ics.description', COUNT: group_slots.count, ITEM: reservation.reservable.name)
            e.ip_class    = "PRIVATE"
          end
        end
      end

      cal.to_ical
    end
  end
end
