# frozen_string_literal:true

class RemoveValueFromSettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :settings, :value, :string
  end
end
