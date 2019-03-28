class AddFootprintToAccountingPeriod < ActiveRecord::Migration
  def change
    add_column :accounting_periods, :footprint, :string
  end
end
