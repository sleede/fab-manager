# frozen_string_literal: true

# CarrierWave uploader for image of product
# This file defines the parameters for these uploads.
class ProductImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include UploadHelper

  # Choose what kind of storage to use for this uploader:
  storage :file
  after :remove, :delete_empty_dirs

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{base_store_dir}/#{model.id}"
  end

  def base_store_dir
    "uploads/#{model.class.to_s.underscore}"
  end

  # Create different versions of your uploaded files:
  version :large do
    process resize_to_fit: [1000, 700]
  end

  version :medium do
    process resize_to_fit: [700, 400]
  end

  version :small do
    process resize_to_fit: [400, 250]
  end

  version :thumb do
    process resize_to_fit: [100, 100]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[jpg jpeg gif png webp]
  end

  def content_type_whitelist
    [%r{image/}]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    return unless original_filename

    original_filename.split('.').map do |s|
      ActiveSupport::Inflector.transliterate(s).to_s
    end.join('.')
  end

  # return an array like [width, height]
  def dimensions
    ::MiniMagick::Image.open(file.file)[:dimensions]
  end
end
