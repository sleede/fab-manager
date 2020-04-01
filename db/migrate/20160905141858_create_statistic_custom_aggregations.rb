# frozen_string_literal:true

class CreateStatisticCustomAggregations < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_custom_aggregations do |t|
      t.text :query
      t.string :path
      t.belongs_to :statistic_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
