class AddReservableToReservation < ActiveRecord::Migration
  def change
    add_reference :reservations, :reservable, index: true, polymorphic: true
  end
end
