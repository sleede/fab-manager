class CreateStatisticFields < ActiveRecord::Migration
  def change
    create_table :statistic_fields do |t|
      t.belongs_to :statistic_index, index: true
      t.string :key
      t.string :label

      t.timestamps
    end
  end
end
