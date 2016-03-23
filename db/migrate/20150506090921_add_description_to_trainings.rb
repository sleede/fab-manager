class AddDescriptionToTrainings < ActiveRecord::Migration
  def change
    add_column :trainings, :description, :text
  end
end
