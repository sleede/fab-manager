# frozen_string_literal: true

# This table saves the restrictions settings, per plan and resource
class CreatePlanLimitations < ActiveRecord::Migration[5.2]
  def change
    create_table :plan_limitations do |t|
      t.references :plan, foreign_key: true, index: true
      t.references :limitable, polymorphic: true
      t.integer :limit, null: false, default: 0

      t.timestamps
    end
  end
end
