# frozen_string_literal: true

# Validates uploaded images to check that it matches the env parameters
# You must `include ImageValidatorConcern` in your class to use it
module ImageValidatorConcern
  extend ActiveSupport::Concern

  included do
    validates :attachment, file_size: { maximum: Rails.application.secrets.max_image_size ? Rails.application.secrets.max_image_size.to_i : 2.megabytes.to_i }
  end
end
