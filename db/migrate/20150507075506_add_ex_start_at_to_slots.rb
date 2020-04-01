# frozen_string_literal:true

class AddExStartAtToSlots < ActiveRecord::Migration[4.2]
  def change
    add_column :slots, :ex_start_at, :datetime
  end
end
