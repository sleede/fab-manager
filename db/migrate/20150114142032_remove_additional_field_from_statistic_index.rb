class RemoveAdditionalFieldFromStatisticIndex < ActiveRecord::Migration
  def change
    remove_column :statistic_indices, :additional_field, :string
  end
end
