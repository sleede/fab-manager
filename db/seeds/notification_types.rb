# frozen_string_literal: true

NOTIFICATIONS_TYPES.each do |notification_type_attrs|
  notification_type = NotificationType.find_by(name: notification_type_attrs[:name])

  if notification_type
    notification_type.update!(notification_type_attrs)
  else
    NotificationType.create!(notification_type_attrs)
  end
end
