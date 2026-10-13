json.title notification.notification_type
json.description t('.supporting_document_files_uploaded',
                   NAME: ERB::Util.html_escape(notification.attached_object&.profile&.full_name || t('api.notifications.deleted_user')))
