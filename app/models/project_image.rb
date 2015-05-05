class ProjectImage < Asset
  mount_uploader :attachment, ProjectImageUploader

  validates :attachment, file_size: { maximum: 2.megabytes.to_i }
end
