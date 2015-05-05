class NotificationType
  include NotifyWith::NotificationType

  # DANGER: dont remove a notification type!!!
  notification_type_names %w(
    notify_admin_when_project_published
    notify_project_collaborator_to_valid
    notify_project_author_when_collaborator_valid
    notify_admin_when_user_is_created
  )
end
