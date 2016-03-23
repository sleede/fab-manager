json.title notification.notification_type
json.description t('.your_subscription_PLAN_was_successfully_cancelled_html',
                   PLAN: notification.attached_object.plan.name)
json.url notification_url(notification, format: :json)
