class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :name, null: false
      t.text :value

      t.timestamps null: false
    end

    add_index :settings, :name, unique: true
  end
end
