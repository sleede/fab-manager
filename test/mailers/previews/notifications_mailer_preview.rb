# frozen_string_literal: true

class NotificationsMailerPreview < ActionMailer::Preview
  def notify_user_auth_migration
    notif = Notification.where(notification_type_id: NotificationType.find_by_name('notify_user_auth_migration')).first
    NotificationsMailer.send_mail_by(notif)
  end
end
