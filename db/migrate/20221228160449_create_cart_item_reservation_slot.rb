# frozen_string_literal: true

# A relation table between a pending reservation and a slot
class CreateCartItemReservationSlot < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_reservation_slots do |t|
      t.references :cart_item, polymorphic: true, index: { name: 'index_cart_item_slots_on_cart_item' }
      t.references :slot, foreign_key: true
      t.references :slots_reservation, foreign_key: true
      t.boolean :offered, default: false

      t.timestamps
    end
  end
end
