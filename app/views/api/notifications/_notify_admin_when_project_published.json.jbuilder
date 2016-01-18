json.title notification.notification_type
json.description "The project <a href='/#!/projects/#{notification.attached_object.id}'><strong><em>#{notification.attached_object.name}<em></strong></a> has just been published."
json.url notification_url(notification, format: :json)
