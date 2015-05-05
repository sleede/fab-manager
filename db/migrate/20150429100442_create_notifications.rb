class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :receiver_id
      t.references :attached_object, polymorphic: true
      t.integer :notification_type_id
      t.boolean :is_read, default: false
      t.string :receiver_type
      t.boolean :is_send, default: false

      t.timestamps
    end
    add_index :notifications, :receiver_id
    add_index :notifications, :notification_type_id
  end
end
