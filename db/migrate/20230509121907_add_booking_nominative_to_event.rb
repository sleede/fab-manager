# frozen_string_literal: true

# add booking_nominative to event
class AddBookingNominativeToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :booking_nominative, :boolean, default: false
  end
end
