class AddEsIndexEsTypeToStatisticCustomAggregations < ActiveRecord::Migration
  def change
    add_column :statistic_custom_aggregations, :es_index, :string
    add_column :statistic_custom_aggregations, :es_type, :string
  end
end
