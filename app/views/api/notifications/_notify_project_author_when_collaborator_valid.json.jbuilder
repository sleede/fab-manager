json.title notification.notification_type
json.description " #{notification.attached_object.user.profile.full_name} has become a collaborator of the project <a href='/#!/projects/#{notification.attached_object.project.id}'><strong><em>#{notification.attached_object.project.name}</em></strong></a>."
json.url notification_url(notification, format: :json)
