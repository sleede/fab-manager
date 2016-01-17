json.title notification.notification_type
json.description "A new user account newly created : <strong><em>#{ notification.attached_object.profile.full_name } &lt;#{ notification.attached_object.email}&gt;</strong></em>."
json.url notification_url(notification, format: :json)
