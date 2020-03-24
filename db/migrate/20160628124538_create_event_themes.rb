# frozen_string_literal:true

class CreateEventThemes < ActiveRecord::Migration[4.2]
  def change
    create_table :event_themes do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
