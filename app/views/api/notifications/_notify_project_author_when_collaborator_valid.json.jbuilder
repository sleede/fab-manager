json.title notification.notification_type
user_name = ERB::Util.html_escape(notification.attached_object.user&.profile&.full_name || t('api.notifications.deleted_user'))
project_link = link_to(tag.strong(tag.em(notification.attached_object.project.name)),
                       "/#!/projects/#{notification.attached_object.project.slug}")
json.description "#{t('.USER_became_collaborator_of_your_project', USER: user_name)} #{project_link}."

