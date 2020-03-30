# frozen_string_literal:true

class AddSimpleToStatisticType < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_types, :simple, :boolean
  end
end
