class EventFile < Asset
  mount_uploader :attachment, ProjectCaoUploader

  validates :attachment, file_size: { maximum: 20.megabytes.to_i }
end
