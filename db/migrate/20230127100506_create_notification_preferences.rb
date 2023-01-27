# frozen_string_literal: true

# Create notification preferences : allow user to decide which type of notifications
# they want to receive via push ('in system') or via email.
class CreateNotificationPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :notification_preferences do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :notification_type, index: true, foreign_key: true, null: false
      t.boolean :in_system, default: true
      t.boolean :email, default: true

      t.timestamps
    end
  end
end
