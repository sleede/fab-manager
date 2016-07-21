json.title notification.notification_type
amount = notification.attached_object.amount
json.description t('.your_wallet_is_credited',
                    AMOUNT: number_to_currency(amount))
json.url notification_url(notification, format: :json)
