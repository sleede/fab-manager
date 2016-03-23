json.title t('.unknown_notification')
json.description t('.notification_ID_wrong_type_TYPE_unknown',
                 ID: notification.id,
                 TYPE: notification.notification_type_id)
json.url notification_url(notification, format: :json)
