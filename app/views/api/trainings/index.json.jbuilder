role = (current_user and current_user.is_admin?) ? 'admin' : 'user'

json.cache! [@trainings, role] do
  json.array!(@trainings) do |training|
    json.extract! training, :id, :name, :description, :machine_ids, :nb_total_places, :slug
    json.training_image training.training_image.attachment.large.url if training.training_image
    json.plan_ids training.plan_ids if role === 'admin'
  end
end
