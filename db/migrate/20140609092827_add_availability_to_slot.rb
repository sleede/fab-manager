# frozen_string_literal:true

class AddAvailabilityToSlot < ActiveRecord::Migration[4.2]
  def change
    add_reference :slots, :availability, index: true
  end
end
