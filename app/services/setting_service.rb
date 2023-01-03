# frozen_string_literal: true

# Settings are saved in two database tables: Settings and HistoryValues.
# Due to the way the controller updates the settings, we cannot safely use ActiveRecord's callbacks (eg. after_update, after_commit...)
# so this service provides a wrapper around these operations.
class SettingService
  class << self
    def update_allowed?(setting)
      return false if Rails.application.secrets.locked_settings.include? setting.name

      true
    end

    def run_after_update(settings)
      update_theme_stylesheet(settings)
      update_home_stylesheet(settings)
      notify_privacy_update(settings)
      sync_stripe_objects(settings)
      build_stats(settings)
      export_projects_to_openlab(settings)
      validate_admins(settings)
      update_accounting_line(settings)
    end

    private

    # rebuild the theme stylesheet
    def update_theme_stylesheet(settings)
      return unless (%w[main_color secondary_color] & settings.map(&:name)).count.positive?

      Stylesheet.theme&.rebuild!
    end

    # rebuild the home page stylesheet
    def update_home_stylesheet(settings)
      return unless settings.any? { |s| s.name == 'home_css' }

      Stylesheet.home_page&.rebuild!
    end

    # notify about a change in privacy policy
    def notify_privacy_update(settings)
      return unless settings.any? { |s| s.name == 'privacy_body' }

      setting = settings.find { |s| s.name == 'privacy_body' }
      NotifyPrivacyUpdateWorker.perform_async(setting.id)
    end

    # sync all objects on stripe
    def sync_stripe_objects(settings)
      return unless (%w[stripe_secret_key online_payment_module] & settings.map(&:name)).count.positive?

      setting = settings.find { |s| s.name == 'stripe_secret_key' }
      SyncObjectsOnStripeWorker.perform_async(setting.history_values.last&.invoicing_profile&.user&.id)
    end

    # generate the statistics since the last update
    def build_stats(settings)
      return unless settings.any? { |s| s.name == 'statistics_module' && s.value == 'true' }

      setting = settings.find { |s| s.name == 'statistics_module' }
      PeriodStatisticsWorker.perform_async(setting.previous_update)
    end

    # export projects to openlab
    def export_projects_to_openlab(settings)
      return unless (%w[openlab_app_id openlab_app_secret] & settings.map(&:name)).count.positive? &&
                    Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?

      Project.all.each(&:openlab_create)
    end

    # automatically validate the admins
    def validate_admins(settings)
      return unless settings.any? { |s| s.name == 'user_validation_required' && s.value == 'true' }

      User.admins.each { |admin| admin.update(validated_at: DateTime.current) if admin.validated_at.nil? }
    end

    def update_accounting_line(settings)
      return unless settings.any? { |s| s.name.match(/^accounting_/) || s.name == 'advanced_accounting' }

      AccountingWorker.perform_async(:all)
    end
  end
end
