json.title notification.notification_type
amount = notification.attached_object.total / 100.0
json.description t('.your_avoir_is_ready_html',
                    REFERENCE: notification.attached_object.reference,
                    AMOUNT: number_to_currency(amount),
                    INVOICE_ID: notification.attached_object.id)
json.url notification_url(notification, format: :json)
