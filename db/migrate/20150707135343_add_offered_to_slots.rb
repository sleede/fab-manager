# frozen_string_literal:true

class AddOfferedToSlots < ActiveRecord::Migration[4.2]
  def change
    add_column :slots, :offered, :boolean, :default => false
  end
end
