# frozen_string_literal: true

# Provides methods for SupportingDocumentFile
class SupportingDocumentFileService
  def self.list(operator, filters = {})
    files = []
    if filters[:user_id].present? && (operator.privileged? || filters[:user_id].to_i == operator.id)
      files = SupportingDocumentFile.where(user_id: filters[:user_id])
    end
    files
  end

  def self.create(supporting_document_file)
    saved = supporting_document_file.save

    if saved
      user = User.find(supporting_document_file.user_id)
      all_files_are_upload = true
      user.group.supporting_document_types.each do |type|
        file = type.supporting_document_files.find_by(user_id: supporting_document_file.user_id)
        all_files_are_upload = false unless file
      end
      if all_files_are_upload
        NotificationCenter.call type: 'notify_admin_user_supporting_document_files_created',
                                receiver: User.admins_and_managers,
                                attached_object: user
      end
    end
    saved
  end

  def self.update(supporting_document_file, params)
    updated = supporting_document_file.update(params)
    if updated
      user = supporting_document_file.user
      all_files_are_upload = true
      user.group.supporting_document_types.each do |type|
        file = type.supporting_document_files.find_by(user_id: supporting_document_file.user_id)
        all_files_are_upload = false unless file
      end
      if all_files_are_upload
        NotificationCenter.call type: 'notify_admin_user_supporting_document_files_updated',
                                receiver: User.admins_and_managers,
                                attached_object: supporting_document_file
      end
    end
    updated
  end
end
