json.title notification.notification_type
json.description t('.subscription_partner_PLAN_has_been_subscribed_by_USER_html',
                    {
                        PLAN: notification.attached_object.plan.name,
                        USER: notification.attached_object.user.profile.full_name
                    }) # messageFormat
json.url notification_url(notification, format: :json)
