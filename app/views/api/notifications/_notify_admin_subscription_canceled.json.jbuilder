json.title notification.notification_type
json.description t('.USER_s_subscription_has_been_cancelled',
                   USER: notification.attached_object.user.profile.full_name)
json.url notification_url(notification, format: :json)
