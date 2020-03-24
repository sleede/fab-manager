# frozen_string_literal:true

class AddDescriptionToTrainings < ActiveRecord::Migration[4.2]
  def change
    add_column :trainings, :description, :text
  end
end
