json.user_trainings @user_trainings do |user_training|
  json.extract! user_training, :id, :user_id, :training_id, :updated_at, :created_at

  if user_training.association(:user).loaded?
    json.user do
      json.partial! 'open_api/v1/users/user', user: user_training.user
    end
  end

  if user_training.association(:training).loaded?
    json.training do
      json.partial! 'open_api/v1/trainings/training', training: user_training.training
    end
  end
end
