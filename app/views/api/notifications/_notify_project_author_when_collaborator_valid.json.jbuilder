json.title notification.notification_type
json.description t('.USER_became_collaborator_of_your_project',
                    USER: notification.attached_object.user.profile.full_name) +
                 "<a href='/#!/projects/#{notification.attached_object.project.slug}'><strong><em> #{notification.attached_object.project.name}</em></strong></a>."
json.url notification_url(notification, format: :json)
