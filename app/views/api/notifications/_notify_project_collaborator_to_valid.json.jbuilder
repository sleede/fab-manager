json.title notification.notification_type
project_link = link_to(tag.strong(tag.em(notification.attached_object.project.name)),
                       "/#!/projects/#{notification.attached_object.project.slug}")
json.description "#{t('.you_are_invited_to_collaborate_on_the_project')} #{project_link}."

