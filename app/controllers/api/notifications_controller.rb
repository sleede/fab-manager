class API::NotificationsController < API::ApiController
  include NotifyWith::NotificationsApi
  before_action :authenticate_user!

  def index
    if params[:is_read]
      @notifications = current_user.notifications.where(is_read: params[:is_read] == "true").page(params[:page]).per(15).order('created_at DESC')
    else
      @notifications = current_user.notifications.order('created_at DESC')
    end
  end
end
