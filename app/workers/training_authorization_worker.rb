# frozen_string_literal: true

# This training will periodically check for trainings authorizations to revoke
class TrainingAuthorizationWorker
  include Sidekiq::Worker

  def perform
    Training.find_each do |t|
      Trainings::AuthorizationService.auto_cancel_authorizations(t)
      Trainings::InvalidationService.auto_invalidate(t)
    end
  end
end
