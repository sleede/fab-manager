# frozen_string_literal:true

class AddLockToAvailability < ActiveRecord::Migration[4.2]
  def change
    add_column :availabilities, :lock, :boolean, default: false
  end
end
