# frozen_string_literal: true

# API Controller for resources of type Notification
# Notifications are scoped by user
class API::NotificationsController < API::ApiController
  include NotifyWith::NotificationsApi
  before_action :authenticate_user!

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  NOTIFICATIONS_PER_PAGE = 15

  def index
    loop do
      @notifications = current_user.notifications.page(params[:page]).per(NOTIFICATIONS_PER_PAGE).order('created_at DESC')
      # we delete obsolete notifications on first access
      break unless delete_obsoletes(@notifications)
    end
    @totals = {
      total: current_user.notifications.count,
      unread: current_user.notifications.where(is_read: false).count
    }
    render :index
  end

  def last_unread
    loop do
      @notifications = current_user.notifications.where(is_read: false).limit(3).order('created_at DESC')
      # we delete obsolete notifications on first access
      break unless delete_obsoletes(@notifications)
    end
    @totals = {
      total: current_user.notifications.count,
      unread: current_user.notifications.where(is_read: false).count
    }
    render :index
  end

  def polling
    @notifications = current_user.notifications
                                 .where('is_read = false AND created_at >= :date', date: params[:last_poll])
                                 .order('created_at DESC')
    @totals = {
      total: current_user.notifications.count,
      unread: current_user.notifications.where(is_read: false).count
    }
    render :index
  end

  private

  def delete_obsoletes(notifications)
    cleaned = false
    notifications.each do |n|
      if !Module.const_get(n.attached_object_type) || !n.attached_object
        n.destroy!
        cleaned = true
      end
    end
    cleaned
  end
end
