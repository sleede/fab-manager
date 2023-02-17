# frozen_string_literal: true

# Business logic around trainings
module Trainings; end

# Automatically cancel trainings authorizations if no machines reservations were made during
# the configured period
class Trainings::InvalidationService
  class << self
    # @param training [Training]
    def auto_invalidate(training)
      return unless training.invalidation

      training.statistic_profile_trainings
              .where('created_at < ?', Time.current - training.invalidation_period.months)
              .find_each do |spt|
        reservations_since = spt.statistic_profile
                                .reservations
                                .where(reservable_type: 'Machine', reservable_id: spt.training.machines)
                                .where('created_at > ?', spt.created_at)
                                .count

        next if reservations_since.positive?

        NotificationCenter.call type: 'notify_member_training_invalidated',
                                receiver: spt.statistic_profile.user,
                                attached_object: spt.training
        spt.destroy!
      end
    end

    # update the given training, depending on the provided settings
    # @param training [Training]
    # @param invalidation [Setting,NilClass]
    # @param duration [Setting,NilClass]
    def update_invalidation(training, invalidation, duration)
      previous_invalidation = invalidation.nil? ? Setting.find_by(name: 'trainings_invalidation_rule').value : invalidation.previous_value
      previous_duration = duration.nil? ? Setting.find_by(name: 'trainings_invalidation_rule_period').value : duration.previous_value
      is_default = training.invalidation.to_s == previous_invalidation.to_s &&
                   training.invalidation_period.to_s == previous_duration.to_s

      return unless is_default

      # update parameters if the given training is default
      params = {}
      params[:invalidation] = invalidation.value unless invalidation.nil?
      params[:invalidation_period] = duration.value unless duration.nil?
      training.update(params)
    end

    # @param training [Training]
    # @return [Boolean]
    def override_settings?(training)
      training.invalidation.to_s != Setting.find_by(name: 'trainings_invalidation_rule')&.value.to_s ||
        training.invalidation_period.to_s != Setting.find_by(name: 'trainings_invalidation_rule_period')&.value.to_s
    end
  end
end
