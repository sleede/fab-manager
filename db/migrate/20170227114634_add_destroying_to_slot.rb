# frozen_string_literal:true

class AddDestroyingToSlot < ActiveRecord::Migration[4.2]
  def change
    # this allow to prevent conflicts of 'delete cascade' by marking a slot
    # as 'currently being destroyed'
    add_column :slots, :destroying, :boolean, default: false
  end
end
