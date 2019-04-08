json.title notification.notification_type
json.description t('.archive_complete',
                   START: notification.attached_object.start_at,
                   END: notification.attached_object.end_at,
                   ID: notification.attached_object.id
                 )
json.url notification_url(notification, format: :json)
