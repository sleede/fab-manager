# frozen_string_literal: true

# An admin can mark an uploaded document as refused, this will notify the member
class SupportingDocumentRefusal < ApplicationRecord
  include NotificationAttachedObject

  belongs_to :supportable, polymorphic: true
  belongs_to :operator, class_name: 'User', inverse_of: :supporting_document_refusals
  has_and_belongs_to_many :supporting_document_types
end
