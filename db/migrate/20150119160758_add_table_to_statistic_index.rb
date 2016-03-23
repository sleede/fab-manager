class AddTableToStatisticIndex < ActiveRecord::Migration
  def change
    add_column :statistic_indices, :table, :boolean, default: true
  end
end
