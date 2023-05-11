# frozen_string_literal: true

# Add event_type to event model, to be able to create standard/nominative/family events
class AddEventTypeToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :event_type, :string, default: 'standard'
    Event.reset_column_information
    Event.update_all(event_type: 'standard')
  end
end
