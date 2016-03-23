class AddBaseNameToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :base_name, :string
  end
end
