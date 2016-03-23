class AddExEndAtToSlots < ActiveRecord::Migration
  def change
    add_column :slots, :ex_end_at, :datetime
  end
end
