# frozen_string_literal: true

# API Controller for resources of type Notification Preferences
class API::NotificationPreferencesController < API::APIController
  before_action :authenticate_user!

  def index
    @notification_preferences = current_user.notification_preferences
  end

  # Currently only available for Admin in NotificationPreferencePolicy
  def update
    authorize NotificationPreference
    notification_type = NotificationType.find_by(name: params[:notification_preference][:notification_type])
    @notification_preference = NotificationPreference.find_or_create_by(notification_type: notification_type, user: current_user)
    @notification_preference.update(notification_preference_params)

    if @notification_preference.save
      render :show, status: :ok
    else
      render json: @notification_preference.errors, status: :unprocessable_entity
    end
  end

  # Currently only available for Admin in NotificationPreferencePolicy
  def bulk_update
    authorize NotificationPreference
    errors = []
    params[:notification_preferences].each do |notification_preference|
      notification_type = NotificationType.find_by(name: notification_preference[:notification_type])
      db_notification_preference = NotificationPreference.find_or_create_by(notification_type_id: notification_type.id, user: current_user)

      next if db_notification_preference.update(email: notification_preference[:email], in_system: notification_preference[:in_system])

      errors.push(db_notification_preference.errors)
    end

    if errors.any?
      render json: errors, status: :unprocessable_entity
    else
      head :no_content, status: :ok
    end
  end

  private

  def notification_preference_params
    params.require(:notification_preference).permit(:notification_type_id, :in_system, :email)
  end
end
