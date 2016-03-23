class AddCaToStatisticIndex < ActiveRecord::Migration
  def change
    add_column :statistic_indices, :ca, :boolean, default: true
  end
end
