# frozen_string_literal: true

json.title notification.notification_type
json.description t('.supporting_document_files_uploaded',
                   NAME: notification.attached_object&.supportable&.profile&.full_name || t('api.notifications.deleted_user'))
