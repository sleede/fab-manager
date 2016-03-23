class AddIsAllowContactToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_allow_contact, :boolean, default: true
  end
end
