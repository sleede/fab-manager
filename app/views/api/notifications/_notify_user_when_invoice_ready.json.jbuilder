json.title notification.notification_type
amount = notification.attached_object.total / 100.0
json.description t('.your_invoice_is_ready_html',
                    REFERENCE: notification.attached_object.reference,
                    AMOUNT: number_to_currency(amount, locale: CURRENCY_LOCALE),
                    INVOICE_ID: notification.attached_object.id)
