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
            e.summary     = title
            e.description = description(group_slots)
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

    private

    def title
      case reservable_type
      when 'Machine', 'Training', 'Space'
        reservable.name
      when 'Event'
        reservable.title
      else
        Rails.logger.warn "Unexpected reservable type #{reservable_type}"
        reservable_type
      end
    end

    def description(group_slots)
      case reservable_type
      when 'Machine', 'Space'
        I18n.t('reservation_ics.description_slot', **{ COUNT: group_slots.count, ITEM: reservable.name })
      when 'Training'
        I18n.t('reservation_ics.description_training', **{ TYPE: reservable.name })
      when 'Event'
        I18n.t('reservation_ics.description_event', **{ NUMBER: nb_reserve_places + (tickets.map(&:booked).reduce(:+) || 0) })
      else
        Rails.logger.warn "Unexpected reservable type #{reservable_type}"
        I18n.t('reservation_ics.description_slot', **{ COUNT: group_slots.count, ITEM: reservable_type })
      end
    end
  end
end
