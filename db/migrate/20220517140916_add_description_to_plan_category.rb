class AddDescriptionToPlanCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :plan_categories, :description, :text
  end
end
