# frozen_string_literal: true

json.user_trainings @user_trainings do |user_training|
  json.extract! user_training, :id, :training_id, :updated_at, :created_at

  if user_training.association(:statistic_profile).loaded?
    json.user_id user_training.statistic_profile.user_id
    unless user_training.statistic_profile.user.nil?
      json.user do
        json.partial! 'open_api/v1/users/user', user: user_training.statistic_profile.user
      end
    end
  end

  if user_training.association(:training).loaded?
    json.training do
      json.partial! 'open_api/v1/trainings/training', training: user_training.training
    end
  end
end
