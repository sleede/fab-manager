# frozen_string_literal: true

json.array!(@trainings) do |training|
  json.partial! 'api/trainings/training', training: training
  json.plan_ids training.plan_ids if current_user&.admin?
end
