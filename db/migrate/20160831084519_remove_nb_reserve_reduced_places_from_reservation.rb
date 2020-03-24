# frozen_string_literal:true

class RemoveNbReserveReducedPlacesFromReservation < ActiveRecord::Migration[4.2]
  def change
    remove_column :reservations, :nb_reserve_reduced_places, :integer
  end
end
