json.title notification.notification_type
json.description t('.a_new_child_has_been_created_NAME_html',
                   NAME: notification.attached_object&.full_name || t('api.notifications.deleted_user'))

