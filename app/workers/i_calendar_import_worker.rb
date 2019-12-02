# frozen_string_literal: true

# Periodically import the iCalendar RFC 5545 events from the configured source
class ICalendarImportWorker
  include Sidekiq::Worker

  def perform(calendar_ids = ICalendar.all.map(&:id))
    service = ICalendarImportService.new

    calendar_ids.each do |id|
      service.import(id)
    end
  end
end
