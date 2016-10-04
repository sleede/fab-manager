class CreateEventThemes < ActiveRecord::Migration
  def change
    create_table :event_themes do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
