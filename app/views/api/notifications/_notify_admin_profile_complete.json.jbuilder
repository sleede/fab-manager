json.title notification.notification_type
json.description t('.account_imported_from_PROVIDER_(UID)_has_completed_its_information_html',
                   PROVIDER: notification.attached_object.provider,
                   UID: notification.attached_object.uid)
json.url notification_url(notification, format: :json)
