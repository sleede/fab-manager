# frozen_string_literal:true

class AddTableToStatisticIndex < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_indices, :table, :boolean, default: true
  end
end
