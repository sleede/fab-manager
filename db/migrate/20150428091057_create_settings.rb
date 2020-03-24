# frozen_string_literal:true

class CreateSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.string :name, null: false
      t.text :value

      t.timestamps null: false
    end

    add_index :settings, :name, unique: true
  end
end
