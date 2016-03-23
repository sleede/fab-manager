class AddNbTotalPlacesToTrainings < ActiveRecord::Migration
  def change
    add_column :trainings, :nb_total_places, :integer
  end
end
