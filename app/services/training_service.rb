# frozen_string_literal: true

# Provides methods for Trainings
class TrainingService
  class << self
    # @param filters [ActionController::Parameters]
    def list(filters)
      trainings = Training.includes(:training_image, :plans, :machines)

      trainings = filter_by_disabled(trainings, filters)
      trainings = filter_by_public_page(trainings, filters)

      if filters[:requested_attributes].try(:include?, 'availabilities')
        trainings = trainings.includes(availabilities: [slots: [reservation: [user: %i[profile trainings]]]])
                             .order('availabilities.start_at DESC')
      end

      trainings
    end

    # @param training [Training]
    def auto_cancel_reservation(training)
      return unless training.auto_cancel

      training.availabilities
              .includes(slots: :slots_reservations)
              .where('availabilities.start_at >= ?', DateTime.current - training.auto_cancel_deadline.hours)
              .find_each do |a|
        next if a.reservations.count >= training.auto_cancel_threshold

        a.slots_reservations.find_each do |sr|
          sr.update(canceled_at: DateTime.current)
        end
      end
    end

    private

    # @param trainings [ActiveRecord::Relation<Training>]
    # @param filters [ActionController::Parameters]
    def filter_by_disabled(trainings, filters)
      return trainings if filters[:disabled].blank?

      state = filters[:disabled] == 'false' ? [nil, false] : true
      trainings.where(disabled: state)
    end

    # @param trainings [ActiveRecord::Relation<Training>]
    # @param filters [ActionController::Parameters]
    def filter_by_public_page(trainings, filters)
      return trainings if filters[:public_page].blank?

      state = filters[:public_page] == 'false' ? [nil, false] : true
      trainings.where(public_page: state)
    end
  end
end
