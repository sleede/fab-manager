json.title notification.notification_type
json.description "Vous êtes invité à collaborer sur le projet suivant : <a href='/#!/projects/#{notification.attached_object.project.id}'><strong><em>#{notification.attached_object.project.name}</em></strong></a>."
json.url notification_url(notification, format: :json)
