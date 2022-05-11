json.title notification.notification_type
json.description t('.refusal',
                   NAME: notification.attached_object&.user&.profile&.full_name || t('api.notifications.deleted_user'))
