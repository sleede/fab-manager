role = (current_user and current_user.is_admin?) ? 'admin' : 'user'

json.cache! [@trainings, role] do
  json.array!(@trainings) do |training|
    json.id training.id
    json.name training.name
    json.description training.description
    json.machine_ids training.machine_ids
    json.nb_total_places training.nb_total_places

    json.plan_ids training.plan_ids if role === 'admin'
  end
end
