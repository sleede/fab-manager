# frozen_string_literal: true

# From this migration, we will save the number of reserved places for each slots, for each reservable
# This will improved performance because of computing the number of reserved seats on each request in very resource demanding
#
# The places field is a jsonb object, with the following structure:
# {reservable_type: string, reservable_id: number, reserved_places: number, user_ids: number[]}
class AddPlacesCacheToSlot < ActiveRecord::Migration[5.2]
  def change
    add_column :slots, :places, :jsonb, null: false, default: []
    add_index :slots, :places, using: :gin
  end
end
