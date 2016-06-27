maxMembers = @query.except(:offset, :limit, :order).count

json.array!(@members) do |member|
  json.maxMembers maxMembers
  json.id member.id
  json.email member.email if current_user
  json.profile do
    json.first_name member.profile.first_name
    json.last_name member.profile.last_name
    json.phone member.profile.phone
  end
  json.group do
    json.name member.group.name
  end
  json.subscribed_plan do
    json.partial! 'api/shared/plan', plan: member.subscribed_plan
  end if member.subscribed_plan
end