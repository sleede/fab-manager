# frozen_string_literal: true

# iCalendar (RFC 5545) event, belonging to an ICalendar object (its source)
class ICalendarEvent < ApplicationRecord
  belongs_to :i_calendar

  def self.update_or_create_by(args, attributes)
    obj = find_or_create_by(args)
    obj.update(attributes)
    obj
  end
end
