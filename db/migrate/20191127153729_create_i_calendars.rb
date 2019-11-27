# frozen_string_literal: true

# From this migration, we store URL to iCalendar files and a piece of configuration about them.
# This allows to display the events of these external calendars in fab-manager
class CreateICalendars < ActiveRecord::Migration
  def change
    create_table :i_calendars do |t|
      t.string :url
      t.string :name
      t.string :color
      t.string :text_color
      t.boolean :text_hidden

      t.timestamps null: false
    end
  end
end
