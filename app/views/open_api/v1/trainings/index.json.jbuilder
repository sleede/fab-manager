json.trainings @trainings do |training|
  json.partial! 'open_api/v1/trainings/training', training: training
  json.extract! training, :nb_total_places, :description
end
