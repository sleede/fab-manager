json.array!(@notifications) do |notification|
  if Module.const_get(notification.attached_object_type) and notification.attached_object # WHY WERE WE DOING Object.const_defined?(notification.attached_object_type) ??? Why not just deleting obsolete notifications ?! Object.const_defined? was introducing a bug! Module.const_get is a TEMPORARY fix, NOT a solution
    json.extract! notification, :id, :notification_type_id, :notification_type, :created_at, :is_read
    json.attached_object notification.attached_object
    json.message do
      if notification.notification_type.nil?
        json.partial! 'api/notifications/undefined_notification', notification: notification
      else
        json.partial! "/api/notifications/#{notification.notification_type}", notification: notification
      end
    end
  end
end.delete_if {|n| n['id'] == nil }
