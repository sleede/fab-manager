class AddUiWeightToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :ui_weight, :integer, default: 0
  end
end
