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
    Setting.get('allowed_cad_extensions').split(' ')
  end

  def content_type_whitelist
    Setting.get('allowed_cad_mime_types').split(' ')
  end

  private

  def check_content_type_whitelist!(new_file)
    content_type = Marcel::MimeType.for Pathname.new(new_file.file)

    if content_type_whitelist && content_type && !whitelisted_content_type?(content_type)
      raise CarrierWave::IntegrityError,
            I18n.translate(:'errors.messages.content_type_whitelist_error',
                           content_type: content_type,
                           allowed_types: Array(content_type_whitelist).join(', '))
    end
  end

  def whitelisted_content_type?(content_type)
    Array(content_type_whitelist).any? do |item|
      item = Regexp.quote(item) if item.class != Regexp
      content_type =~ /#{item}/
    end
  end
end
