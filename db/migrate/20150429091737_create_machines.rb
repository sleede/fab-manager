class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.string :name
      t.text :description
      t.text :spec
      t.string :slug

      t.timestamps
    end
    add_index :machines, :slug, unique: true
  end
end
