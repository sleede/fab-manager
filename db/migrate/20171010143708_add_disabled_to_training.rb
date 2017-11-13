class AddDisabledToTraining < ActiveRecord::Migration
  def change
    add_column :trainings, :disabled, :boolean
  end
end
