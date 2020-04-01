# frozen_string_literal:true

class AddBaseNameToPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :base_name, :string
  end
end
