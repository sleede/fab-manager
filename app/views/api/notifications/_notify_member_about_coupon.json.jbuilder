json.title notification.notification_type
json.description t('.enjoy_a_discount_of_PERCENT_with_code_CODE',
                   PERCENT: notification.attached_object.percent_off,
                   CODE: notification.attached_object.code)
json.url notification_url(notification, format: :json)
