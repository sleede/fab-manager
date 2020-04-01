# frozen_string_literal:true

class AddExEndAtToSlots < ActiveRecord::Migration[4.2]
  def change
    add_column :slots, :ex_end_at, :datetime
  end
end
