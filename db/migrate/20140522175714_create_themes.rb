# frozen_string_literal:true

class CreateThemes < ActiveRecord::Migration[4.2]
  def change
    create_table :themes do |t|
      t.string :name, null: false
    end
  end
end
