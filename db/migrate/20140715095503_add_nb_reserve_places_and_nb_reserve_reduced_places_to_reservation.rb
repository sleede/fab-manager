# frozen_string_literal:true

class AddNbReservePlacesAndNbReserveReducedPlacesToReservation < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :nb_reserve_places, :integer
    add_column :reservations, :nb_reserve_reduced_places, :integer
  end
end
