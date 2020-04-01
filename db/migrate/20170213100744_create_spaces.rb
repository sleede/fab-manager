# frozen_string_literal:true

class CreateSpaces < ActiveRecord::Migration[4.2]
  def change
    create_table :spaces do |t|
      t.string :name
      t.integer :default_places
      t.text :description
      t.string :slug

      t.timestamps null: false
    end
  end
end
