class CreateStatisticTypeSubTypes < ActiveRecord::Migration
  def change
    create_table :statistic_type_sub_types do |t|
      t.belongs_to :statistic_type, index: true
      t.belongs_to :statistic_sub_type, index: true

      t.timestamps
    end
  end
end
