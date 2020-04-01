# frozen_string_literal:true

class CreateTickets < ActiveRecord::Migration[4.2]
  def change
    create_table :tickets do |t|
      t.belongs_to :reservation, index: true, foreign_key: true
      t.belongs_to :event_price_category, index: true, foreign_key: true
      t.integer :booked

      t.timestamps null: false
    end
  end
end
