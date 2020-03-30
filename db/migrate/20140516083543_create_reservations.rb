# frozen_string_literal:true

class CreateReservations < ActiveRecord::Migration[4.2]
  def change
    create_table :reservations do |t|
      t.belongs_to :user, index: true
      t.text :message

      t.timestamps
    end
  end
end
