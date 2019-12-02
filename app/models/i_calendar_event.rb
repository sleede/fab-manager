# frozen_string_literal: true

# iCalendar (RFC 5545) event, belonging to an ICalendar object (its source)
class ICalendarEvent < ActiveRecord::Base
  belongs_to :i_calendar
end
