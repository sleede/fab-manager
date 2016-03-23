class RemoveStatisticTypeIdFromStatisticSubType < ActiveRecord::Migration
  def change
    remove_column :statistic_sub_types, :statistic_type_id, :integer
  end
end
