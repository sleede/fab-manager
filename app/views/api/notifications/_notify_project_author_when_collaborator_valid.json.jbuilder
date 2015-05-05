json.title notification.notification_type
json.description "Le membre #{notification.attached_object.user.profile.full_name} est devenu un collaborateur de votre projet <a href='/#!/projects/#{notification.attached_object.project.id}'><strong><em>#{notification.attached_object.project.name}</em></strong></a>."
json.url notification_url(notification, format: :json)
