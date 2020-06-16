# frozen_string_literal: true

json.title notification.notification_type
json.description t('.user_NAME_changed_ROLE_html',
                   NAME: notification.attached_object&.profile&.full_name || t('api.notifications.deleted_user'),
                   ROLE: t("roles.#{notification.attached_object&.role}"))

