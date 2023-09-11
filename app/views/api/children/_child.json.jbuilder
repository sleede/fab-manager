# frozen_string_literal: true

json.extract! child, :id, :first_name, :last_name, :email, :birthday, :phone, :user_id, :validated_at
json.supporting_document_files_attributes child.supporting_document_files do |f|
  json.id f.id
  json.supportable_id f.supportable_id
  json.supportable_type f.supportable_type
  json.supporting_document_type_id f.supporting_document_type_id
  json.attachment f.attachment.file&.filename
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_identifier ? "/api/supporting_document_files/#{f.id}/download" : nil
end
