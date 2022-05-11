# frozen_string_literal: true

# Adds support for iCalendar formar (RFC 5545) to reservations
module ICalendarConcern
  extend ActiveSupport::Concern
  require 'icalendar'
  require 'icalendar/tzinfo'

  included do
    def to_ics
      cal = Icalendar::Calendar.new
      cal.add_timezone Time.zone.tzinfo.ical_timezone Time.zone.now
      build_icalendar(cal)
      cal.to_ical
    end

    def ics_filename
      "#{self.class.name.downcase}-#{id}.ics"
    end

    def build_icalendar(cal)
      grouped_slots.each do |_date, daily_groups|
        daily_groups.each do |start_time, group_slots|
          cal.event do |e|
            e.dtstart     = start_time
            e.dtend       = group_slots.last[:end_at]
            e.summary     = I18n.t('reservation_ics.summary', TYPE: I18n.t("reservation_ics.type.#{reservable.class.name}"))
            e.description = I18n.t('reservation_ics.description', COUNT: group_slots.count, ITEM: reservable.name)
            e.ip_class    = 'PRIVATE'

            e.alarm do |a|
              a.action = 'DISPLAY'
              a.summary = I18n.t('reservation_ics.alarm_summary')
              a.trigger = '-P1DT0H0M0S'
            end
          end
        end
      end
      cal
    end
  end
end
