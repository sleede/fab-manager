# frozen_string_literal: true

# @deprecated
# <b>DEPRECATED:</b> Feature removed in v2.8.2
json.title notification.notification_type
json.description _t('.invoices_generation_was_STATUS_for_user_NAME_html',
                    STATUS: notification.attached_object.invoicing_disabled.to_s,
                    NAME: notification.attached_object.profile.full_name) # messageFormat
json.url notification_url(notification, format: :json)
