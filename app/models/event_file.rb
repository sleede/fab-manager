# frozen_string_literal: true

# EventFile is a PDF attachment for Events
class EventFile < Asset
  mount_uploader :attachment, EventFileUploader

  validates :attachment, file_size: { maximum: 20.megabytes.to_i }
end
