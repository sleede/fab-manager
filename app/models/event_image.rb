class EventImage < Asset
  mount_uploader :attachment, EventImageUploader

  validates :attachment, file_size: { maximum: 2.megabytes.to_i }
end
