# frozen_string_literal: true

# This training will periodically check for trainings reservations to auto-cancel
class TrainingAutoCancelWorker
  include Sidekiq::Worker

  def perform
    Training.find_each do |t|
      Trainings::AutoCancelService.auto_cancel_reservations(t)
    end
  end
end
