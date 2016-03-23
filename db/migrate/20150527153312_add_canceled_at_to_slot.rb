class AddCanceledAtToSlot < ActiveRecord::Migration
  def change
    add_column :slots, :canceled_at, :datetime, default: nil
  end
end
