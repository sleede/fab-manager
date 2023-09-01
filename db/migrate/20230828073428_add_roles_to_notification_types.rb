class AddRolesToNotificationTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :notification_types, :roles, :string, array: true, default: []
    add_index :notification_types, :roles
    load Rails.root.join('db/seeds/notification_types.rb')
  end
end
