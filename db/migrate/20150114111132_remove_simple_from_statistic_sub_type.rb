# frozen_string_literal:true

class RemoveSimpleFromStatisticSubType < ActiveRecord::Migration[4.2]
  def change
    remove_column :statistic_sub_types, :simple, :boolean
  end
end
