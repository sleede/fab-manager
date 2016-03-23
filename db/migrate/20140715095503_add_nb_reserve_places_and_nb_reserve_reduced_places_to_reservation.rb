class AddNbReservePlacesAndNbReserveReducedPlacesToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :nb_reserve_places, :integer
    add_column :reservations, :nb_reserve_reduced_places, :integer
  end
end
