class AddIntervalCountToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :interval_count, :integer, default: 1
  end
end
