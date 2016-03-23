class AddOfferedToSlots < ActiveRecord::Migration
  def change
    add_column :slots, :offered, :boolean, :default => false
  end
end
