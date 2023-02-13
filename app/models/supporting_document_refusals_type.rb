# frozen_string_literal: true

# Associate SupportingDocumentRefusal with a SupportingDocumentType
# When an admin refuses an uploaded document, he can specify which type of document was refused using this association table
class SupportingDocumentRefusalsType < ApplicationRecord
  belongs_to :supporting_document_refusal
  belongs_to :supporting_document_type
end
