# frozen_string_literal:true

class CreateAgeRanges < ActiveRecord::Migration[4.2]
  def change
    create_table :age_ranges do |t|
      t.string :range

      t.timestamps null: false
    end
  end
end
