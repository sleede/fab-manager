# frozen_string_literal:true

class AddNbTotalPlacesToTrainings < ActiveRecord::Migration[4.2]
  def change
    add_column :trainings, :nb_total_places, :integer
  end
end
