# frozen_string_literal: true

# CarrierWave uploader for project CAO attachments.
# This file defines the parameters for these uploads
class ProjectCaoUploader < CarrierWave::Uploader::Base
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

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    ENV['ALLOWED_EXTENSIONS'].split(' ')
  end
end
