# frozen_string_literal: true

# create booking_users table
class CreateBookingUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :booking_users do |t|
      t.string :name
      t.belongs_to :reservation, foreign_key: true
      t.references :booked, polymorphic: true
      t.references :event_price_category, foreign_key: true

      t.timestamps
    end
  end
end
