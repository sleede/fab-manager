json.extract! @notification, :id, :notification_type_id, :notification_type, :created_at, :is_read
json.attached_object @notification.attached_object
json.message do
  json.partial! "/api/notifications/#{@notification.notification_type}", notification: @notification
end
