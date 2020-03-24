# frozen_string_literal:true

class AddCanceledAtToSlot < ActiveRecord::Migration[4.2]
  def change
    add_column :slots, :canceled_at, :datetime, default: nil
  end
end
