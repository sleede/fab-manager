# frozen_string_literal:true

class CreateTrainings < ActiveRecord::Migration[4.2]
  def change
    create_table :trainings do |t|
      t.string :name

      t.timestamps
    end
  end
end
