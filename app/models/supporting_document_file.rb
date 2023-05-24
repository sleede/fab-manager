# frozen_string_literal: true

require 'file_size_validator'

class SupportingDocumentFile < ApplicationRecord
  mount_uploader :attachment, SupportingDocumentFileUploader

  belongs_to :supporting_document_type
  belongs_to :supportable, polymorphic: true

  validates :attachment, file_size: { maximum: ENV.fetch('MAX_SUPPORTING_DOCUMENT_FILE_SIZE', 5.megabytes).to_i }
end
