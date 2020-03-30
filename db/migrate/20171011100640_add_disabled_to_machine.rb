# frozen_string_literal:true

class AddDisabledToMachine < ActiveRecord::Migration[4.2]
  def change
    add_column :machines, :disabled, :boolean
  end
end
