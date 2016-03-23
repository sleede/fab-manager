json.title notification.notification_type
json.description t('.a_RESERVABLE_reservation_was_made_by_USER_html',
                   RESERVABLE: notification.attached_object.reservable.name,
                   USER: notification.attached_object.user.profile.full_name)
json.url notification_url(notification, format: :json)
