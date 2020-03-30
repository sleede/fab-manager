# frozen_string_literal:true

class AddIsActiveAttributeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_active, :boolean, default: true
  end
end
