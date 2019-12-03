# frozen_string_literal: true

# Import all events from a given remote RFC 5545 iCalendar
class ICalendarImportService
  def import(i_calendar_id)
    require 'net/http'
    require 'uri'
    require 'icalendar'

    events = []

    i_cal = ICalendar.find(i_calendar_id)
    ics = Net::HTTP.get(URI.parse(i_cal.url))
    cals = Icalendar::Calendar.parse(ics)

    cals.each do |cal|
      cal.events.each do |evt|
        events.push(
          uid: evt.uid,
          dtstart: evt.dtstart,
          dtend: evt.dtend,
          summary: evt.summary,
          description: evt.description,
          i_calendar_id: i_calendar_id
        )
      end
    end

    ICalendarEvent.create!(events)
  end
end
