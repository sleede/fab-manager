class AddFootprintToHistoryValues < ActiveRecord::Migration
  def change
    add_column :history_values, :footprint, :string
  end
end
