# frozen_string_literal:true

class CreateStatisticSubTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_sub_types do |t|
      t.belongs_to :statistic_type, index: true
      t.string :key
      t.string :label

      t.timestamps
    end
  end
end
