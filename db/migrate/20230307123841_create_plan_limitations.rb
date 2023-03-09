# frozen_string_literal: true

# This table saves the restrictions settings, per plan and resource
class CreatePlanLimitations < ActiveRecord::Migration[5.2]
  def change
    create_table :plan_limitations do |t|
      t.references :plan, foreign_key: true, index: true, null: false
      t.references :limitable, polymorphic: true, null: false
      t.integer :limit, null: false, default: 0

      t.timestamps
    end

    add_index :plan_limitations, %i[plan_id limitable_id limitable_type], unique: true, name: 'index_plan_limitations_on_plan_and_limitable'
  end
end
