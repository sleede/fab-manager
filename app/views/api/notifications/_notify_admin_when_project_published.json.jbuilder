json.title notification.notification_type
json.description "Le projet <a href='/#!/projects/#{notification.attached_object.id}'><strong><em>#{notification.attached_object.name}<em></strong></a> vient d'être publié."
json.url notification_url(notification, format: :json)
