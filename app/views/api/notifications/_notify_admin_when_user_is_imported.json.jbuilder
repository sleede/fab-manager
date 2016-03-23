json.title notification.notification_type
json.description t('.a_new_user_account_has_been_imported_from_PROVIDER_(UID)_html',
                   PROVIDER: notification.attached_object.provider,
                   UID: notification.attached_object.uid)
json.url notification_url(notification, format: :json)