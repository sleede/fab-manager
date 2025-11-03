json.array!(@members) do |member|
  json.maxMembers @max_members
  json.id member.id
  json.username member.username
  json.email member.email if current_user
  json.profile do
    json.first_name member.profile.first_name
    json.last_name member.profile.last_name
    json.phone member.profile.phone
  end
  json.need_completion member.need_completion?
  json.group do
    json.name member.group&.name
  end
  if member.subscribed_plan
    json.subscribed_plan do
      json.partial! 'api/shared/plan', plan: member.subscribed_plan
    end
  end
  json.validated_at member.validated_at
  json.children member.children.where('birthday >= ?', 18.years.ago).order(:created_at) do |child|
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
  end
end
