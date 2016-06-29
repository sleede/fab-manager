class EventTheme < ActiveRecord::Base
  has_and_belongs_to_many :events, join_table: :events_event_themes, dependent: :destroy
end
