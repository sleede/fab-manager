# frozen_string_literal:true

class CreateStatisticFields < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_fields do |t|
      t.belongs_to :statistic_index, index: true
      t.string :key
      t.string :label

      t.timestamps
    end
  end
end
