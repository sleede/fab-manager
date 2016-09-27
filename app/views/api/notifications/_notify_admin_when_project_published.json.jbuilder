json.title notification.notification_type
json.description t('.project_NAME_has_been_published_html',
                   ID: notification.attached_object.slug,
                   NAME: notification.attached_object.name)
json.url notification_url(notification, format: :json)
