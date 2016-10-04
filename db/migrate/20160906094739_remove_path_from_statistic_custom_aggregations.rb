class RemovePathFromStatisticCustomAggregations < ActiveRecord::Migration
  def change
    remove_column :statistic_custom_aggregations, :path, :string
  end
end
