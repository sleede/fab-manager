json.title notification.notification_type
json.description t('.a_new_user_account_has_been_created_NAME_EMAIL_html',
                   NAME: notification.attached_object&.profile&.full_name || t('api.notifications.deleted_user'),
                   EMAIL: notification.attached_object&.email)

