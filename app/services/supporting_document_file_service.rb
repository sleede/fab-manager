# frozen_string_literal: true

# Provides methods for SupportingDocumentFile
class SupportingDocumentFileService
  def self.list(operator, filters = {})
    files = []
    if filters[:supportable_id].present? && can_list?(operator, filters[:supportable_id], filters[:supportable_type])
      files = SupportingDocumentFile.where(supportable_id: filters[:supportable_id], supportable_type: filters[:supportable_type])
    end
    files
  end

  def self.can_list?(operator, supportable_id, supportable_type)
    operator.privileged? ||
      (supportable_type == 'User' && supportable_id.to_i == operator.id) ||
      (supportable_type == 'Child' && operator.children.exists?(id: supportable_id.to_i))
  end

  def self.create(supporting_document_file)
    saved = supporting_document_file.save

    if saved
      all_files_are_upload = true
      if supporting_document_file.supportable_type == 'User'
        user = supporting_document_file.supportable
        user.group.supporting_document_types.each do |type|
          file = type.supporting_document_files.find_by(supportable_id: supporting_document_file.supportable_id,
                                                        supportable_type: supporting_document_file.supportable_type)
          all_files_are_upload = false unless file
        end
      end
      if all_files_are_upload && (supporting_document_file.supportable_type == 'User')
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
      all_files_are_upload = true
      if supporting_document_file.supportable_type == 'User'
        user = supporting_document_file.supportable
        user.group.supporting_document_types.each do |type|
          file = type.supporting_document_files.find_by(supportable_id: supporting_document_file.supportable_id,
                                                        supportable_type: supporting_document_file.supportable_type)
          all_files_are_upload = false unless file
        end
      end
      if all_files_are_upload && (supporting_document_file.supportable_type == 'User')
        NotificationCenter.call type: 'notify_admin_user_supporting_document_files_updated',
                                receiver: User.admins_and_managers,
                                attached_object: supporting_document_file
      end
    end
    updated
  end
end
