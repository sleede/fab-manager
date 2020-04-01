# frozen_string_literal:true

class AddCaToStatisticIndex < ActiveRecord::Migration[4.2]
  def change
    add_column :statistic_indices, :ca, :boolean, default: true
  end
end
