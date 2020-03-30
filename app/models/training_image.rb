# frozen_string_literal: true

# TrainingImage is the main picture for a Training
class TrainingImage < Asset
  mount_uploader :attachment, TrainingImageUploader
end