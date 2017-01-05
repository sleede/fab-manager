json.totals @totals
json.notifications(@notifications) do |notification|
  json.extract! notification, :id, :notification_type_id, :notification_type, :created_at, :is_read
  json.attached_object notification.attached_object
  json.message do
    if notification.notification_type.nil?
      json.partial! 'api/notifications/undefined_notification', notification: notification
    else
      json.partial! "/api/notifications/#{notification.notification_type}", notification: notification
    end
  end
end.delete_if {|n| n['id'] == nil }
