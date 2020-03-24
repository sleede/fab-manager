# frozen_string_literal:true

class RemovePathFromStatisticCustomAggregations < ActiveRecord::Migration[4.2]
  def change
    remove_column :statistic_custom_aggregations, :path, :string
  end
end
