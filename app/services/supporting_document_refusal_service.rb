# frozen_string_literal: true

# Provides methods for SupportingDocumentRefusal
class SupportingDocumentRefusalService
  def self.list(filters = {})
    refusals = []
    refusals = SupportingDocumentRefusal.where(user_id: filters[:user_id]) if filters[:user_id].present?
    refusals
  end

  def self.create(supporting_document_refusal)
    saved = supporting_document_refusal.save

    if saved
      NotificationCenter.call type: 'notify_admin_user_supporting_document_refusal',
                              receiver: User.admins_and_managers,
                              attached_object: supporting_document_refusal
      NotificationCenter.call type: 'notify_user_supporting_document_refusal',
                              receiver: supporting_document_refusal.user,
                              attached_object: supporting_document_refusal
    end
    saved
  end
end
