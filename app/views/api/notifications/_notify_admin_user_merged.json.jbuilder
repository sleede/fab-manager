json.title notification.notification_type
json.description _t('.user_NAME_has_merged_his_account_with_the_one_imported_from_PROVIDER_(UID)_html',
                    {
                        NAME: notification.attached_object.profile.full_name,
                        GENDER: bool_to_sym(notification.attached_object.profile.gender),
                        PROVIDER: notification.attached_object.provider,
                        UID: notification.attached_object.uid
                    }) # messageFormat
json.url notification_url(notification, format: :json)
