# frozen_string_literal: true

# CarrierWave uploader for proof of identity file of user
# This file defines the parameters for these uploads.
class ProofOfIdentityFileUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  include UploadHelper

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  after :remove, :delete_empty_dirs

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{base_store_dir}/#{model.id}"
  end

  def base_store_dir
    "../proof_of_identity_files"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_pack_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[pdf png jpeg jpg]
  end

  def content_type_whitelist
    [%r{image/}, 'application/pdf']
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    original_filename.split('.').map do |s|
      ActiveSupport::Inflector.transliterate(s).to_s
    end.join('.') if original_filename
  end

end
