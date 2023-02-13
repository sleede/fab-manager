# frozen_string_literal: true

class SupportingDocumentTypesGroup < ApplicationRecord
  belongs_to :supporting_document_type
  belongs_to :group
end
