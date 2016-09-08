class EventTheme < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :events, join_table: :events_event_themes, dependent: :destroy

  def safe_destroy
    if self.events.count == 0
      destroy
    else
      false
    end
  end
end
