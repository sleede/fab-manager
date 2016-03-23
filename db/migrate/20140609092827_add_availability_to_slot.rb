class AddAvailabilityToSlot < ActiveRecord::Migration
  def change
    add_reference :slots, :availability, index: true
  end
end
