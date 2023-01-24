# frozen_string_literal: true

# This training will periodically check for trainings reservations to auto-cancel
class TrainingAutoCancelWorker
  include Sidekiq::Worker

  def perform
    Training.find_each do |t|
      TrainingService.auto_cancel_reservation(t)
    end
  end
end
