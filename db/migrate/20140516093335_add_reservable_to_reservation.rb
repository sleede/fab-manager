# frozen_string_literal:true

class AddReservableToReservation < ActiveRecord::Migration[4.2]
  def change
    add_reference :reservations, :reservable, index: true, polymorphic: true
  end
end
