# frozen_string_literal:true

class CreateSlotsReservations < ActiveRecord::Migration[4.2]
  def change
    create_table :slots_reservations do |t|
      t.belongs_to :slot, index: true, foreign_key: true
      t.belongs_to :reservation, index: true, foreign_key: true
    end
  end
end
