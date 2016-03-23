class AddIsActiveAttributeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_active, :boolean, default: true
  end
end
