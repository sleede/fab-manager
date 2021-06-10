# frozen_string_literal: true

# Allows to sort plans into categories
class CreatePlanCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :plan_categories do |t|
      t.string :name
      t.integer :weight

      t.timestamps
    end
    add_reference :plans, :plan_category, index: true, foreign_key: true
  end
end
