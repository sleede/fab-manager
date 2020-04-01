# frozen_string_literal:true

class AddEsIndexEsTypeToStatisticCustomAggregations < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_custom_aggregations, :es_index, :string
    add_column :statistic_custom_aggregations, :es_type, :string
  end
end
