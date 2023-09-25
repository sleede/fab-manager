# frozen_string_literal: true

# Send a notification to users who did not upload their supporting document files yet
class SupportingDocumentsReminderWorker
  include Sidekiq::Worker

  def perform
    users_to_notify = User.members
                          .supporting_documents_reminder_not_sent
                          .where("users.created_at < ?", 2.days.ago)
                          .joins("LEFT OUTER JOIN supporting_document_files ON supporting_document_files.supportable_id = users.id AND supporting_document_files.supportable_type = 'User' LEFT OUTER JOIN supporting_document_types ON supporting_document_types.id = supporting_document_files.supporting_document_type_id LEFT OUTER JOIN supporting_document_types_groups ON supporting_document_types_groups.supporting_document_type_id = supporting_document_types.id LEFT OUTER JOIN groups ON groups.id = supporting_document_types_groups.group_id")
                          .where("groups.id = users.group_id OR groups.id IS NULL")
                          .select("users.*, count(supporting_document_files.id)")
                          .group("users.id")
                          .having("(count(supporting_document_files.id)) < (SELECT count(supporting_document_types.id) "\
                                                                           "FROM supporting_document_types "\
                                                                           "INNER JOIN supporting_document_types_groups "\
                                                                           "ON supporting_document_types_groups.supporting_document_type_id = supporting_document_types.id "\
                                                                           "WHERE supporting_document_types_groups.group_id = users.group_id)")
    users_to_notify.each do |user|
      NotificationCenter.call type: 'notify_user_supporting_document_reminder',
                              receiver: user,
                              attached_object: user
      user.update_column(:supporting_documents_reminder_sent_at, DateTime.current)
    end
  end
end
