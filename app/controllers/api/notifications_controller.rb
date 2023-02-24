# frozen_string_literal: true

# API Controller for resources of type Notification
# Notifications are scoped by user
class API::NotificationsController < API::APIController
  before_action :authenticate_user!
  before_action :set_notification, only: :update

  # notifications can have anything attached, so we won't eager load the whole database
  around_action :skip_bullet, if: -> { defined?(Bullet) }

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  NOTIFICATIONS_PER_PAGE = 15

  def index
    loop do
      @notifications = current_user.notifications
                                   .delivered_in_system(current_user)
                                   .includes(:attached_object)
                                   .page(params[:page])
                                   .per(NOTIFICATIONS_PER_PAGE)
                                   .order('created_at DESC')
      # we delete obsolete notifications on first access
      break unless delete_obsoletes(@notifications)
    end
    @totals = {
      total: current_user.notifications.delivered_in_system(current_user).count,
      unread: current_user.notifications.delivered_in_system(current_user).where(is_read: false).count
    }
    render :index
  end

  def last_unread
    loop do
      @notifications = current_user.notifications
                                   .delivered_in_system(current_user)
                                   .includes(:attached_object)
                                   .where(is_read: false)
                                   .limit(3)
                                   .order('created_at DESC')
      # we delete obsolete notifications on first access
      break unless delete_obsoletes(@notifications)
    end
    @totals = {
      total: current_user.notifications.delivered_in_system(current_user).count,
      unread: current_user.notifications.delivered_in_system(current_user).where(is_read: false).count
    }
    render :index
  end

  def polling
    @notifications = current_user.notifications
                                 .where('is_read = false AND created_at >= :date', date: params[:last_poll])
                                 .order('created_at DESC')
    @totals = {
      total: current_user.notifications.delivered_in_system(current_user).count,
      unread: current_user.notifications.delivered_in_system(current_user).where(is_read: false).count
    }
    render :index
  end

  def update
    @notification.mark_as_read
    render :show
  end

  def update_all
    current_user.notifications.where(is_read: false).find_each(&:mark_as_read)
    head :no_content
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

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
