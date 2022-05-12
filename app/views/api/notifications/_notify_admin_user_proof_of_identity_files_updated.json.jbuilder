json.title notification.notification_type
json.description t('.proof_of_identity_files_uploaded',
                   NAME: notification.attached_object&.user&.profile&.full_name || t('api.notifications.deleted_user'))
