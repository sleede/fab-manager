# frozen_string_literal:true

class RemoveAdditionalFieldFromStatisticIndex < ActiveRecord::Migration[4.2]
  def change
    remove_column :statistic_indices, :additional_field, :string
  end
end
