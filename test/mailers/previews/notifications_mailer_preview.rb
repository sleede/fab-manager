# frozen_string_literal: true

class NotificationsMailerPreview < ActionMailer::Preview
  def notify_user_auth_migration
    notif = Notification.find_by(notification_type_id: NotificationType.find_by(name: 'notify_user_auth_migration'))
    NotificationsMailer.send_mail_by(notif)
  end
end
