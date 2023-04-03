# frozen_string_literal: true

# Settings are saved in two database tables: Settings and HistoryValues.
# Due to the way the controller updates the settings, we cannot safely use ActiveRecord's callbacks (eg. after_update, after_commit...)
# so this service provides a wrapper around these operations.
class SettingService
  class << self
    # @param setting [Setting]
    def update_allowed?(setting)
      return false if Rails.application.secrets.locked_settings.include? setting.name

      true
    end

    # @param setting [Hash{Symbol->String}]
    # @return [StandardError,NilClass]
    def check_before_update(setting)
      check_home_scss(setting)
    end

    # @param setting [Setting]
    # @param value [String]
    # @param operator [User]
    def save_and_update(setting, value, operator)
      return false unless setting.save

      val = parse_value(setting.name, value)
      setting.history_values.create(value: val, invoicing_profile: operator.invoicing_profile)
    end

    # @param settings [Array<Setting>]
    def run_after_update(settings)
      update_theme_stylesheet(settings)
      update_home_stylesheet(settings)
      notify_privacy_update(settings)
      sync_stripe_objects(settings)
      build_stats(settings)
      export_projects_to_openlab(settings)
      validate_admins(settings)
      update_accounting_line(settings)
      update_trainings_auto_cancel(settings)
      update_trainings_authorization(settings)
      update_trainings_invalidation(settings)
    end

    private

    # @param setting [String]
    # @param value [String]
    def parse_value(setting, value)
      return value unless %w[booking_window_start booking_window_end].include?(setting)

      Time.zone.parse(value)
    end

    # rebuild the theme stylesheet
    # @param settings [Array<Setting>]
    def update_theme_stylesheet(settings)
      return unless (%w[main_color secondary_color] & settings.map(&:name)).count.positive?

      Stylesheet.theme&.rebuild!
    end

    # validate that the provided SCSS has a valid syntax
    # @param setting [Hash{Symbol->String}]
    def check_home_scss(setting)
      return nil unless setting[:name] == 'home_css'

      engine = SassC::Engine.new(".home-page { #{setting[:value]} }", style: :compressed)
      engine.render
      nil
    rescue StandardError => e
      e
    end

    # rebuild the home page stylesheet
    # @param settings [Array<Setting>]
    def update_home_stylesheet(settings)
      return unless settings.any? { |s| s.name == 'home_css' }

      Stylesheet.home_page&.rebuild!
    end

    # notify about a change in privacy policy
    # @param settings [Array<Setting>]
    def notify_privacy_update(settings)
      return unless settings.any? { |s| s.name == 'privacy_body' }

      setting = settings.find { |s| s.name == 'privacy_body' }
      NotifyPrivacyUpdateWorker.perform_async(setting.id)
    end

    # sync all objects on stripe
    # @param settings [Array<Setting>]
    def sync_stripe_objects(settings)
      return unless (%w[stripe_secret_key online_payment_module] & settings.map(&:name)).count.positive?

      setting = settings.find { |s| s.name == 'stripe_secret_key' }
      SyncObjectsOnStripeWorker.perform_async(setting.history_values.last&.invoicing_profile&.user&.id)
    end

    # generate the statistics since the last update
    # @param settings [Array<Setting>]
    def build_stats(settings)
      return unless settings.any? { |s| s.name == 'statistics_module' && s.value == 'true' }

      setting = settings.find { |s| s.name == 'statistics_module' }
      PeriodStatisticsWorker.perform_async(setting.previous_update)
    end

    # export projects to openlab
    # @param settings [Array<Setting>]
    def export_projects_to_openlab(settings)
      return unless (%w[openlab_app_id openlab_app_secret] & settings.map(&:name)).count.positive? &&
                    Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?

      Project.find_each(&:openlab_create)
    end

    # automatically validate the admins
    # @param settings [Array<Setting>]
    def validate_admins(settings)
      return unless settings.any? { |s| s.name == 'user_validation_required' && s.value == 'true' }

      User.admins.each { |admin| admin.update(validated_at: Time.current) if admin.validated_at.nil? }
    end

    # rebuild accounting lines
    # @param settings [Array<Setting>]
    def update_accounting_line(settings)
      return unless settings.any? { |s| s.name.match(/^accounting_/) || s.name == 'advanced_accounting' }

      AccountingWorker.perform_async(:all)
    end

    # update tranings auto_cancel parameters
    # @param settings [Array<Setting>]
    def update_trainings_auto_cancel(settings)
      return unless settings.any? { |s| s.name.match(/^trainings_auto_cancel/) }

      tac = settings.find { |s| s.name == 'trainings_auto_cancel' }
      threshold = settings.find { |s| s.name == 'trainings_auto_cancel_threshold' }
      deadline = settings.find { |s| s.name == 'trainings_auto_cancel_deadline' }

      Training.find_each do |t|
        Trainings::AutoCancelService.update_auto_cancel(t, tac, threshold, deadline)
      end
    end

    # update trainings authorization parameters
    # @param settings [Array<Setting>]
    def update_trainings_authorization(settings)
      return unless settings.any? { |s| s.name.match(/^trainings_authorization_validity/) }

      authorization = settings.find { |s| s.name == 'trainings_authorization_validity' }
      duration = settings.find { |s| s.name == 'trainings_authorization_validity_duration' }

      Training.find_each do |t|
        Trainings::AuthorizationService.update_authorization(t, authorization, duration)
      end
    end

    # update trainings invalidation parameters
    # @param settings [Array<Setting>]
    def update_trainings_invalidation(settings)
      return unless settings.any? { |s| s.name.match(/^trainings_invalidation_rule/) }

      invalidation = settings.find { |s| s.name == 'trainings_invalidation_rule' }
      duration = settings.find { |s| s.name == 'trainings_invalidation_rule_period' }

      Training.find_each do |t|
        Trainings::InvalidationService.update_invalidation(t, invalidation, duration)
      end
    end
  end
end
