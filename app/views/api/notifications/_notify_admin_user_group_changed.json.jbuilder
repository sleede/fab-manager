json.title notification.notification_type
json.description _t('.user_NAME_changed_his_group_html',
                    {
                        NAME: notification.attached_object.profile.full_name,
                        GENDER: bool_to_sym(notification.attached_object.profile.gender)
                    }) # messageFormat
json.url notification_url(notification, format: :json)
