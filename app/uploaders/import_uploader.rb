# frozen_string_literal: true

# CarrierWave uploader for import files.
# This file defines the parameters for these uploads
class ImportUploader < CarrierWave::Uploader::Base
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
    '../imports'
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    ['csv']
  end
end
