json.title notification.notification_type
json.description t('.reminder_you_have_a_reservation_RESERVABLE_to_be_held_on_DATE_html',
                   RESERVABLE: notification.attached_object.reservable.name,
                   DATE: I18n.l(notification.attached_object.slots.order(:start_at).first.start_at, format: :long))
json.url notification_url(notification, format: :json)
