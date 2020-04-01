# frozen_string_literal:true

class AddNbTotalPlacesToAvailability < ActiveRecord::Migration[4.2]
  def change
    add_column :availabilities, :nb_total_places, :integer
  end
end
