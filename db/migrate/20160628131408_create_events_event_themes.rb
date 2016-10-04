class CreateEventsEventThemes < ActiveRecord::Migration
  def change
    create_table :events_event_themes do |t|
      t.belongs_to :event, index: true, foreign_key: true
      t.belongs_to :event_theme, index: true, foreign_key: true
    end
  end
end
