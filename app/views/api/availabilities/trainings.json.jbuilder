json.array!(@availabilities) do |a|
  json.id a.id
  json.slot_id a.slot_id if a.slot_id
  if a.is_reserved
    json.is_reserved true
    json.title "#{a.trainings[0].name}' - #{t('trainings.i_ve_reserved')}"
  elsif a.is_completed
    json.is_completed true
    json.title "#{a.trainings[0].name} - #{t('trainings.completed')}"
  else
    json.title a.trainings[0].name
  end
  json.borderColor trainings_events_border_color(a)
  json.start a.start_at.iso8601
  json.end a.end_at.iso8601
  json.backgroundColor 'white'
  json.can_modify a.can_modify
  json.nb_total_places a.nb_total_places

  json.training do
    json.id a.trainings.first.id
    json.name a.trainings.first.name
    json.description a.trainings.first.description
    json.machines a.trainings.first.machines do |m|
      json.id m.id
      json.name m.name
    end
  end
  json.tag_ids a.tag_ids
  json.tags a.tags do |t|
    json.id t.id
    json.name t.name
  end
end
