# frozen_string_literal:true

class CreateStatisticGraphs < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_graphs do |t|
      t.belongs_to :statistic_index, index: true
      t.string :chart_type
      t.integer :limit

      t.timestamps
    end
  end
end
