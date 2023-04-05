# frozen_string_literal: true

# Provides methods for SupportingDocumentType
class SupportingDocumentTypeService
  def self.list(filters = {})
    if filters[:group_id].present?
      group = Group.find_by(id: filters[:group_id])
      return nil if group.nil?

      group.supporting_document_types.includes(:groups)
    else
      SupportingDocumentType.all
    end
  end
end
