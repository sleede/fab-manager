json.title notification.notification_type
json.description t('.you_are_invited_to_collaborate_on_the_project') +
                 "<a href='/#!/projects/#{notification.attached_object.project.slug}'><strong><em>#{notification.attached_object.project.name}</em></strong></a>."
json.url notification_url(notification, format: :json)
