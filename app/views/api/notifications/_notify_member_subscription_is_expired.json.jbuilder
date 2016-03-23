json.title notification.notification_type
json.description t('.your_subscription_has_expired')
json.url notification_url(notification, format: :json)
