# frozen_string_literal:true

class CreateTrainingsPricings < ActiveRecord::Migration[4.2]
  def change
    create_table :trainings_pricings do |t|
      t.belongs_to :machine, index: true
      t.belongs_to :group, index: true
      t.integer :amount

      t.timestamps
    end
  end
end
