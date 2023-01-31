# frozen_string_literal: true

# Business logic around trainings
module Trainings; end

# Automatically cancel trainings authorizations when the configured period has expired
class Trainings::AuthorizationService
  class << self
    # @param training [Training]
    def auto_cancel_authorizations(training)
      return unless training.authorization

      training.statistic_profile_trainings
              .where('created_at < ?', DateTime.current - training.authorization_period.months)
              .find_each do |spt|
        NotificationCenter.call type: 'notify_member_training_authorization_expired',
                                receiver: spt.statistic_profile.user,
                                attached_object: spt.training
        spt.destroy!
      end
    end

    # update the given training, depending on the provided settings
    # @param training [Training]
    # @param authorization [Setting,NilClass]
    # @param duration [Setting,NilClass]
    def update_authorization(training, authorization, duration)
      previous_authorization = if authorization.nil?
                                 Setting.find_by(name: 'trainings_authorization_validity').value
                               else
                                 authorization.previous_value
                               end
      previous_duration = duration.nil? ? Setting.find_by(name: 'trainings_authorization_validity_duration').value : duration.previous_value
      is_default = training.authorization.to_s == previous_authorization.to_s &&
                   training.authorization_period.to_s == previous_duration.to_s

      return unless is_default

      # update parameters if the given training is default
      params = {}
      params[:authorization] = authorization.value unless authorization.nil?
      params[:authorization_period] = duration.value unless duration.nil?
      training.update(params)
    end

    # @param training [Training]
    # @return [Boolean]
    def override_settings?(training)
      training.authorization.to_s != Setting.find_by(name: 'trainings_authorization_validity')&.value.to_s ||
        training.authorization_period.to_s != Setting.find_by(name: 'trainings_authorization_validity_duration')&.value.to_s
    end
  end
end
