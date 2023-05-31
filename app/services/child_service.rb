# frozen_string_literal: true

# ChildService
class ChildService
  def self.create(child)
    if child.save
      NotificationCenter.call type: 'notify_admin_child_created',
                              receiver: User.admins_and_managers,
                              attached_object: child
      all_files_are_upload = true
      SupportingDocumentType.where(document_type: 'Child').each do |sdt|
        file = sdt.supporting_document_files.find_by(supportable: child)
        all_files_are_upload = false if file.nil? || file.attachment_identifier.nil?
      end
      if all_files_are_upload
        NotificationCenter.call type: 'notify_admin_user_child_supporting_document_files_created',
                                receiver: User.admins_and_managers,
                                attached_object: child
      end

      return true
    end
    false
  end

  def self.update(child, child_params)
    if child.update(child_params)
      all_files_are_upload = true
      SupportingDocumentType.where(document_type: 'Child').each do |sdt|
        file = sdt.supporting_document_files.find_by(supportable: child)
        all_files_are_upload = false if file.nil? || file.attachment_identifier.nil?
      end
      if all_files_are_upload
        NotificationCenter.call type: 'notify_admin_user_child_supporting_document_files_updated',
                                receiver: User.admins_and_managers,
                                attached_object: child
      end

      return true
    end
    false
  end

  def self.validate(child, is_valid)
    is_updated = child.update(validated_at: is_valid ? Time.current : nil)
    if is_updated
      if is_valid
        NotificationCenter.call type: 'notify_user_child_is_validated',
                                receiver: child.user,
                                attached_object: child
      else
        NotificationCenter.call type: 'notify_user_child_is_invalidated',
                                receiver: child.user,
                                attached_object: child
      end
    end
    is_updated
  end
end
