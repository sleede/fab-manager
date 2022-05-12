json.array!(@members) do |member|
  json.maxMembers @max_members
  json.id member.id
  json.email member.email if current_user
  json.profile do
    json.first_name member.profile.first_name
    json.last_name member.profile.last_name
    json.phone member.profile.phone
  end
  json.need_completion member.need_completion?
  json.group do
    json.name member.group.name
  end
  if member.subscribed_plan
    json.subscribed_plan do
      json.partial! 'api/shared/plan', plan: member.subscribed_plan
    end
  end
  json.validated_at member.validated_at
end
