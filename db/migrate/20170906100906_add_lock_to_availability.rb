class AddLockToAvailability < ActiveRecord::Migration
  def change
    add_column :availabilities, :lock, :boolean, default: false
  end
end
