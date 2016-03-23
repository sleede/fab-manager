class AddSimpleToStatisticSubType < ActiveRecord::Migration
  def change
    add_column :statistic_sub_types, :simple, :boolean
  end
end
