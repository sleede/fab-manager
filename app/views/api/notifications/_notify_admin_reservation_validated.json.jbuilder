json.title notification.notification_type
json.description t('.a_RESERVABLE_reservation_was_validated_html',
                   RESERVABLE: notification.attached_object.reservable.name,
                   NAME: notification.attached_object.user&.profile&.full_name || t('api.notifications.deleted_user'))
