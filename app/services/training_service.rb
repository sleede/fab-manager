# frozen_string_literal: true

# Provides methods for Trainings
class TrainingService
  def self.list(filters)
    trainings = Training.includes(:training_image, :plans, :machines)

    if filters[:disabled].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      trainings = trainings.where(disabled: state)
    end
    if filters[:public_page].present?
      state = filters[:public_page] == 'false' ? [nil, false] : true
      trainings = trainings.where(public_page: state)
    end
    if filters[:requested_attributes].try(:include?, 'availabilities')
      trainings = trainings.includes(availabilities: [slots: [reservation: [user: %i[profile trainings]]]])
                           .order('availabilities.start_at DESC')
    end

    trainings
  end
end
