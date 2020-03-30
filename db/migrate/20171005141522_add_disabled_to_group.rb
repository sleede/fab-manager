# frozen_string_literal:true

class AddDisabledToGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :disabled, :boolean
  end
end
