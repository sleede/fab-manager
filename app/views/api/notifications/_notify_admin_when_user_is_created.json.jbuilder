json.title notification.notification_type
json.description "Un nouveau compte utilisateur vient d'être créé : <strong><em>#{ notification.attached_object.profile.full_name } &lt;#{ notification.attached_object.email}&gt;</strong></em>."
json.url notification_url(notification, format: :json)
