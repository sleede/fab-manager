# frozen_string_literal:true

class AddIsAllowContactToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_allow_contact, :boolean, default: true
  end
end
