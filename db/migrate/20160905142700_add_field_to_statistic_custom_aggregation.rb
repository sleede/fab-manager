class AddFieldToStatisticCustomAggregation < ActiveRecord::Migration
  def change
    add_column :statistic_custom_aggregations, :field, :string
  end
end
