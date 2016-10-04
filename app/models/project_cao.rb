class ProjectCao < Asset
  mount_uploader :attachment, ProjectCaoUploader

  validates :attachment, file_size: { maximum: 20.megabytes.to_i }
  validates :attachment, :file_mime_type => { :content_type => ENV['ALLOWED_MIME_TYPES'].split(' ') }
end
