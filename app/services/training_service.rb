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

    # update the given training, depending on the provided settings
    # @param training [Training]
    # @param auto_cancel [Setting,NilClass]
    # @param threshold [Setting,NilClass]
    # @param deadline [Setting,NilClass]
    def update_auto_cancel(training, auto_cancel, threshold, deadline)
      previous_auto_cancel = auto_cancel.nil? ? Setting.find_by(name: 'trainings_auto_cancel').value : auto_cancel.previous_value
      previous_threshold = threshold.nil? ? Setting.find_by(name: 'trainings_auto_cancel_threshold').value : threshold.previous_value
      previous_deadline = deadline.nil? ? Setting.find_by(name: 'trainings_auto_cancel_deadline').value : deadline.previous_value
      is_default = training.auto_cancel.to_s == previous_auto_cancel &&
                   [nil, previous_threshold].include?(training.auto_cancel_threshold.to_s) &&
                   [nil, previous_deadline].include?(training.auto_cancel_deadline.to_s)

      return unless is_default

      # update parameters if the given training is default
      params = {}
      params[:auto_cancel] = auto_cancel.value unless auto_cancel.nil?
      params[:auto_cancel_threshold] = threshold.value unless threshold.nil?
      params[:auto_cancel_deadline] = deadline.value unless deadline.nil?
      training.update(params)
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
