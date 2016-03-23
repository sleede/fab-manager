json.array!(@availabilities) do |a|
  json.id a.id
  json.slot_id a.slot_id if a.slot_id
  if a.is_reserved
    json.title "#{a.trainings[0].name}' - #{t('trainings.i_ve_reserved')}"
  elsif a.is_completed
    json.title "#{a.trainings[0].name} - #{t('trainings.completed')}"
  else
    json.title a.trainings[0].name
  end
  json.start a.start_at.iso8601
  json.end a.end_at.iso8601
  json.is_reserved a.is_reserved
  json.backgroundColor 'white'
  json.borderColor a.is_reserved ? '#b2e774' : '#bd7ae9'
  if a.is_reserved
    json.borderColor '#b2e774'
  elsif a.is_completed
    json.borderColor '#eeeeee'
  else
    json.borderColor '#bd7ae9'
  end
  json.can_modify a.can_modify
  json.is_completed a.is_completed
  json.nb_total_places a.nb_total_places

  json.training do
    json.id a.trainings.first.id
    json.name a.trainings.first.name
    json.description a.trainings.first.description
    json.machines a.trainings.first.machines do |m|
      json.id m.id
      json.name m.name
    end
    json.amount a.trainings.first.amount_by_group(@user.group_id).amount_by_plan(nil)/100.0 if @user
  end
  json.tag_ids a.tag_ids
  json.tags a.tags do |t|
    json.id t.id
    json.name t.name
  end
end
