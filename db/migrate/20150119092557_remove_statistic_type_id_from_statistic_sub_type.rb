# frozen_string_literal:true

class RemoveStatisticTypeIdFromStatisticSubType < ActiveRecord::Migration[4.2]
  def change
    remove_column :statistic_sub_types, :statistic_type_id, :integer
  end
end
