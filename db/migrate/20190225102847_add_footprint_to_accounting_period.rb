# frozen_string_literal:true

class AddFootprintToAccountingPeriod < ActiveRecord::Migration[4.2]
  def change
    add_column :accounting_periods, :footprint, :string
  end
end
