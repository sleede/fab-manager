class AddDisabledToMachine < ActiveRecord::Migration
  def change
    add_column :machines, :disabled, :boolean
  end
end
