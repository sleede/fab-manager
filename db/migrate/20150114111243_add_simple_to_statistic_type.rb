class AddSimpleToStatisticType < ActiveRecord::Migration
  def change
    add_column :statistic_types, :simple, :boolean
  end
end
