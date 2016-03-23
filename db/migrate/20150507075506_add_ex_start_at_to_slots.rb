class AddExStartAtToSlots < ActiveRecord::Migration
  def change
    add_column :slots, :ex_start_at, :datetime
  end
end
