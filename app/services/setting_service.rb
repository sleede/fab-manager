# frozen_string_literal: true

# Settings are saved in two database tables: Settings and HistoryValues.
# Due to the way the controller updates the settings, we cannot safely use ActiveRecord's callbacks (eg. after_update, after_commit...)
# so this service provides a wrapper around these operations.
class SettingService
  class << self
    def before_update(setting)
      return false if Rails.application.secrets.locked_settings.include? setting.name

      true
    end

    def after_update(setting)
      update_theme_stylesheet(setting)
      update_home_stylesheet(setting)
      notify_privacy_update(setting)
      sync_stripe_objects(setting)
      build_stats(setting)
      export_projects_to_openlab(setting)
      validate_admins(setting)
    end

    private

    # rebuild the theme stylesheet
    def update_theme_stylesheet(setting)
      return unless %w[main_color secondary_color].include? setting.name

      Stylesheet.theme&.rebuild!
    end

    # rebuild the home page stylesheet
    def update_home_stylesheet(setting)
      return unless setting.name == 'home_css'

      Stylesheet.home_page&.rebuild!
    end

    # notify about a change in privacy policy
    def notify_privacy_update(setting)
      return unless setting.name == 'privacy_body'

      NotifyPrivacyUpdateWorker.perform_async(setting.id)
    end

    # sync all objects on stripe
    def sync_stripe_objects(setting)
      return unless %w[stripe_secret_key online_payment_module].include?(setting.name)

      SyncObjectsOnStripeWorker.perform_async(setting.history_values.last&.invoicing_profile&.user&.id)
    end

    # generate the statistics since the last update
    def build_stats(setting)
      return unless setting.name == 'statistics_module' && setting.value == 'true'

      PeriodStatisticsWorker.perform_async(setting.previous_update)
    end

    # export projects to openlab
    def export_projects_to_openlab(setting)
      return unless %w[openlab_app_id openlab_app_secret].include?(setting.name) &&
                    Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?

      Project.all.each(&:openlab_create)
    end

    # automatically validate the admins
    def validate_admins(setting)
      return unless setting.name == 'user_validation_required' && setting.value == 'true'

      User.admins.each { |admin| admin.update(validated_at: DateTime.current) if admin.validated_at.nil? }
    end
  end
end
