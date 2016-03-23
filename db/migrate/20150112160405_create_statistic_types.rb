class CreateStatisticTypes < ActiveRecord::Migration
  def change
    create_table :statistic_types do |t|
      t.belongs_to :statistic_index, index: true
      t.string :key
      t.string :label
      t.boolean :graph

      t.timestamps
    end
  end
end
