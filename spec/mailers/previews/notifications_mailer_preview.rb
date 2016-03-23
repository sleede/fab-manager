class NotificationsMailerPreview < ActionMailer::Preview
  NotificationType::NAMES.each do |name|
    define_method name do
      NotificationsMailer.send_mail_by(Notification.where(notification_type_id: NotificationType.find_by_name(name)).last)
    end
  end
end
