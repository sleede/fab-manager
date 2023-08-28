# frozen_string_literal: true

# API Controller for resources of type Notification Types
class API::NotificationTypesController < API::APIController
  before_action :authenticate_user!

  def index
    @notification_types = if params[:is_configurable] == 'true'
                            role = 'admin' if current_user.admin?
                            role ||= 'manager' if current_user.manager?
                            NotificationType.where(is_configurable: true).for_role(role)
                          else
                            NotificationType.all
                          end
  end
end
