# frozen_string_literal: true

# From this migration, we are able to store events from an external calendar (using the iCalendar standard format)
class CreateICalendarEvents < ActiveRecord::Migration
  def change
    create_table :i_calendar_events do |t|
      t.string :uid
      t.datetime :dtstart
      t.datetime :dtend
      t.string :summary
      t.string :description
      t.string :attendee
      t.belongs_to :i_calendar, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
