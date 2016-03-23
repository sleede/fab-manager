json.title notification.notification_type
json.description _t('.your_subscription_PLAN_has_been_extended_FREE_until_DATE_html',
                    {
                        PLAN: notification.attached_object.plan.name,
                        FREE: notification.get_meta_data(:free_days).to_s,
                        DATE: I18n.l(notification.attached_object.expired_at.to_date)
                    }) # messageFormat
json.url notification_url(notification, format: :json)
