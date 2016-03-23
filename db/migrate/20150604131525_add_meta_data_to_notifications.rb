class AddMetaDataToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :meta_data, :jsonb, default: '{}'
  end
end
