class AddNbTotalPlacesToAvailability < ActiveRecord::Migration
  def change
    add_column :availabilities, :nb_total_places, :integer
  end
end
