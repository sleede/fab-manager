# frozen_string_literal: true

json.title notification.notification_type
json.description t('.refusal',
                   NAME: ERB::Util.html_escape(notification.attached_object&.supportable&.full_name || t('api.notifications.deleted_user')))
