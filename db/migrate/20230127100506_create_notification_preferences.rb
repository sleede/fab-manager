# frozen_string_literal: true

# Create notification preferences : allow user to decide which type of notifications
# they want to receive via push ('in system') or via email.
class CreateNotificationPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :notification_preferences do |t|
      t.references :user, index: false, foreign_key: true, null: false
      t.references :notification_type, index: true, foreign_key: true, null: false
      t.boolean :in_system, default: true
      t.boolean :email, default: true

      t.index %i[user_id notification_type_id], unique: true, name: :index_notification_preferences_on_user_and_notification_type

      t.timestamps
    end
  end
end
