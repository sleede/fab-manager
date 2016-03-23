json.title notification.notification_type
json.description t('.an_abuse_was_reported_on_TYPE_ID_NAME_html',
                   TYPE: notification.attached_object.signaled_type,
                   ID: notification.attached_object.signaled_id,
                   NAME: (notification.attached_object.signaled.name ? notification.attached_object.signaled.name :  ''))
json.url notification_url(notification, format: :json)