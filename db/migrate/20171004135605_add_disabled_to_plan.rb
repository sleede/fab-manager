class AddDisabledToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :disabled, :boolean
  end
end
