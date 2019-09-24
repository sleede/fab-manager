# frozen_string_literal: true

require 'file_size_validator'

# An Import is a file uploaded by an user that provides some data to the database.
# Currently, this is used to import some users from a CSV file
class Import < ActiveRecord::Base
  mount_uploader :attachment, ImportUploader

  belongs_to :author, foreign_key: :author_id, class_name: 'User'

  validates :attachment, file_size: { maximum: Rails.application.secrets.max_import_size&.to_i || 5.megabytes.to_i }
  validates :attachment, file_mime_type: { content_type: ['text/csv'] }
end
