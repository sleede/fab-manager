# frozen_string_literal:true

class AddSimpleToStatisticSubType < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_sub_types, :simple, :boolean
  end
end
