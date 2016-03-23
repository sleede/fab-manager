class PlanImage < Asset
  mount_uploader :attachment, PlanImageUploader
  validates :attachment, file_size: { maximum: 2.megabytes.to_i }
end
