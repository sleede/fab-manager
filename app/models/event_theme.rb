# frozen_string_literal: true

# EventTheme is an optional filter used to categorize Events
class EventTheme < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :events, join_table: 'events_event_themes', dependent: :destroy

  def safe_destroy
    if events.count.zero?
      destroy
    else
      false
    end
  end
end
