# frozen_string_literal:true

class CreateMachines < ActiveRecord::Migration[4.2]
  def change
    create_table :machines do |t|
      t.string :name, null: false
      t.text :description
      t.text :spec

      t.timestamps
    end
  end
end
