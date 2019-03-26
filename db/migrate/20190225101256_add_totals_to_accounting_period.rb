class AddTotalsToAccountingPeriod < ActiveRecord::Migration
  def change
    add_column :accounting_periods, :period_total, :integer
    add_column :accounting_periods, :perpetual_total, :integer
  end
end
