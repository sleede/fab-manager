class AddReceiverTypeAndIsSendToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :receiver_type, :string
    add_column :notifications, :is_send, :boolean, default: false

    Notification.update_all(receiver_type: 'User', is_send: true)
  end
end
