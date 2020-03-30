# frozen_string_literal:true

class AddDisabledToPlan < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :disabled, :boolean
  end
end
