# frozen_string_literal:true

class AddDisabledToSpace < ActiveRecord::Migration[4.2]
  def change
    add_column :spaces, :disabled, :boolean
  end
end
