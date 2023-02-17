# frozen_string_literal: true

# Provides methods for SupportingDocumentType
class SupportingDocumentTypeService
  def self.list(filters = {})
    if filters[:group_id].present?
      group = Group.find(filters[:group_id])
      group.supporting_document_types.includes(:groups)
    else
      SupportingDocumentType.all
    end
  end
end
