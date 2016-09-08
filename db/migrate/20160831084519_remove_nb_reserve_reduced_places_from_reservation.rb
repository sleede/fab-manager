class RemoveNbReserveReducedPlacesFromReservation < ActiveRecord::Migration
  def change
    remove_column :reservations, :nb_reserve_reduced_places, :integer
  end
end
