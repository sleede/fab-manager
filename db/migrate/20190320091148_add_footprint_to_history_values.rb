# frozen_string_literal:true

class AddFootprintToHistoryValues < ActiveRecord::Migration[4.2]
  def change
    add_column :history_values, :footprint, :string
  end
end
