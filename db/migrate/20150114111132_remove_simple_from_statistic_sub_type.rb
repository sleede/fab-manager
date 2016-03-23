class RemoveSimpleFromStatisticSubType < ActiveRecord::Migration
  def change
    remove_column :statistic_sub_types, :simple, :boolean
  end
end
