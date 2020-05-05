# frozen_string_literal: true

json.title notification.notification_type
json.description t('.your_role_is_ROLE', ROLE: t("roles.#{notification.attached_object&.role}"))
json.url notification_url(notification, format: :json)
