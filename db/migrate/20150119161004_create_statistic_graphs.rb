class CreateStatisticGraphs < ActiveRecord::Migration
  def change
    create_table :statistic_graphs do |t|
      t.belongs_to :statistic_index, index: true
      t.string :chart_type
      t.integer :limit

      t.timestamps
    end
  end
end
