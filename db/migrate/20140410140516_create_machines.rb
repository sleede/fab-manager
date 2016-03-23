class CreateMachines < ActiveRecord::Migration
  def change
    create_table :machines do |t|
      t.string :name, null: false
      t.text :description
      t.text :spec

      t.timestamps
    end
  end
end
