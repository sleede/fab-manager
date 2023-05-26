# frozen_string_literal: true

# Provides methods for SupportingDocumentRefusal
class SupportingDocumentRefusalService
  def self.list(filters = {})
    refusals = []
    if filters[:supportable_id].present?
      refusals = SupportingDocumentRefusal.where(supportable_id: filters[:supportable_id],
                                                 supportable_type: filters[:supportable_type])
    end
    refusals
  end

  def self.create(supporting_document_refusal)
    saved = supporting_document_refusal.save

    if saved
      case supporting_document_refusal.supportable_type
      when 'User'
        NotificationCenter.call type: 'notify_admin_user_supporting_document_refusal',
                                receiver: User.admins_and_managers,
                                attached_object: supporting_document_refusal
        NotificationCenter.call type: 'notify_user_supporting_document_refusal',
                                receiver: supporting_document_refusal.supportable,
                                attached_object: supporting_document_refusal
      when 'Child'
        NotificationCenter.call type: 'notify_admin_user_child_supporting_document_refusal',
                                receiver: User.admins_and_managers,
                                attached_object: SupportingDocumentRefusal.last
        NotificationCenter.call type: 'notify_user_child_supporting_document_refusal',
                                receiver: SupportingDocumentRefusal.last.supportable.user,
                                attached_object: SupportingDocumentRefusal.last
      end
    end
    saved
  end
end
