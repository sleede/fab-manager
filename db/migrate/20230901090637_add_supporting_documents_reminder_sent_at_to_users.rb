class AddSupportingDocumentsReminderSentAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :supporting_documents_reminder_sent_at, :datetime
  end
end
