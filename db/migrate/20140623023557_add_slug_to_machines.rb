# frozen_string_literal:true

class AddSlugToMachines < ActiveRecord::Migration[4.2]
  def change
    add_column :machines, :slug, :string
    add_index :machines, :slug, unique: true
  end
end
