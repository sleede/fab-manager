# frozen_string_literal:true

class AddUiWeightToPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :ui_weight, :integer, default: 0
  end
end
