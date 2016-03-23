class DropMachinesPricings < ActiveRecord::Migration
  def up
    drop_table :machines_pricings
  end
end
