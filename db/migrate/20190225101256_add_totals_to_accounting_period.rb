# frozen_string_literal:true

class AddTotalsToAccountingPeriod < ActiveRecord::Migration[4.2]
  def change
    add_column :accounting_periods, :period_total, :integer
    add_column :accounting_periods, :perpetual_total, :integer
  end
end
