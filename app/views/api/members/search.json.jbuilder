json.array!(@members) do |member|
  json.id member.id
  json.name "#{member.profile.first_name} #{member.profile.last_name}"
  json.group_id member.group_id
  json.need_completion member.need_completion?
end