json.title notification.notification_type
json.description t('.your_reservation_RESERVABLE_was_successfully_saved_html',
                   RESERVABLE: notification.attached_object.reservable.name)
json.url notification_url(notification, format: :json)
