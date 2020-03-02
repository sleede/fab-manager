json.title notification.notification_type
json.description t('.refund_created',
                   AMOUNT: number_to_currency(notification.attached_object.total / 100.00),
                   USER: notification.attached_object.invoicing_profile&.full_name)
json.url notification_url(notification, format: :json)
