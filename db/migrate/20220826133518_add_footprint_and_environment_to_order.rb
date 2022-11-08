class AddFootprintAndEnvironmentToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :footprint, :string
    add_column :orders, :environment, :string
  end
end
