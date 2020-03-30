# frozen_string_literal:true

class AddIntervalCountToPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :interval_count, :integer, default: 1
  end
end
