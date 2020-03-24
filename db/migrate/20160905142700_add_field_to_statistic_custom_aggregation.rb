# frozen_string_literal:true

class AddFieldToStatisticCustomAggregation < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_custom_aggregations, :field, :string
  end
end
