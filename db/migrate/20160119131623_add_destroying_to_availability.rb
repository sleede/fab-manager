class AddDestroyingToAvailability < ActiveRecord::Migration
  def change
    # this allow to prevent conflicts of 'delete cascade' by marking an availability
    # as 'currently being destroyed'
    add_column :availabilities, :destroying, :boolean, default: false
  end
end
