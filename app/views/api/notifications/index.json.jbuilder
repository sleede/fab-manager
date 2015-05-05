json.array!(@notifications) do |notification|
  if notification.attached_object
    json.extract! notification, :id, :notification_type_id, :notification_type, :created_at, :is_read
    json.attached_object notification.attached_object
    json.message do
      json.partial! "/api/notifications/#{notification.notification_type}", notification: notification
    end
  end
end.delete_if {|n| n['id'] == nil }
