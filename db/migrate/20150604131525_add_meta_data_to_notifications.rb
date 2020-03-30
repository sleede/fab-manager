# frozen_string_literal:true

class AddMetaDataToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :meta_data, :jsonb, default: '{}'
  end
end
