# frozen_string_literal:true

class AddAttributesToPlan < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :is_rolling, :boolean, default: true
    add_column :plans, :description, :text
    add_column :plans, :type, :string
  end
end
