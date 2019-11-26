# frozen_string_literal: true

# API Controller for resources of type iCalendar
class API::IcalController < API::ApiController
  respond_to :json

  def externals
    require 'net/http'
    require 'uri'

    ics = Net::HTTP.get(URI.parse('https://calendar.google.com/calendar/ical/sylvain%40sleede.com/public/basic.ics'))

    require 'icalendar'
    require 'icalendar/tzinfo'

    cals = Icalendar::Calendar.parse(ics)
    @events = cals.first.events
  end
end