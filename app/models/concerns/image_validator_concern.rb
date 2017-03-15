module ImageValidatorConcern
  extend ActiveSupport::Concern

  included do
    validates :attachment, file_size: { maximum: Rails.application.secrets.max_image_size ? Rails.application.secrets.max_image_size.to_i : 2.megabytes.to_i }
  end
end
