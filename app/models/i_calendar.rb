# frozen_string_literal: true

# iCalendar (RFC 5545) files, stored by URL and kept with their display configuration
class ICalendar < ActiveRecord::Base
  has_many :i_calendar_events

  after_create sync_events

  private

  def sync_events
    worker = ICalendarImportWorker.new
    worker.perform([id])
  end
end
