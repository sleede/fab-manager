# frozen_string_literal: true

# EventsEventTheme is the relation table between an Event and an EventTheme
# => theme associated with an Event
class EventsEventTheme < ApplicationRecord
  belongs_to :event
  belongs_to :event_theme
end
