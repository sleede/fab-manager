# frozen_string_literal:true

# From this migration any availability can override the default SLOT_DURATION value for its own slots
class AddSlotDurationToAvailability < ActiveRecord::Migration[5.2]
  def change
    add_column :availabilities, :slot_duration, :integer
  end
end
