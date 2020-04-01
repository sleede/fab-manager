# frozen_string_literal:true

class AddDestroyingToAvailability < ActiveRecord::Migration[4.2]
  def change
    # this allow to prevent conflicts of 'delete cascade' by marking an availability
    # as 'currently being destroyed'
    add_column :availabilities, :destroying, :boolean, default: false
  end
end
