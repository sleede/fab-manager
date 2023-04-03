# frozen_string_literal: true

# API Controller for resources of type Notification Types
class API::NotificationTypesController < API::APIController
  before_action :authenticate_user!

  def index
    @notification_types = if params[:is_configurable] == 'true'
                            NotificationType.where(is_configurable: true)
                          else
                            NotificationType.all
                          end
  end
end
