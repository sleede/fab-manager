class AddDestroyingToSlot < ActiveRecord::Migration
  def change
    # this allow to prevent conflicts of 'delete cascade' by marking a slot
    # as 'currently being destroyed'
    add_column :slots, :destroying, :boolean, default: false
  end
end
