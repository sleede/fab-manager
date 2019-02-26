json.title notification.notification_type
json.description t('warning_disk_space_under_threshold', THRESHOLD: notification.meta_data.threshold)
json.url notification_url(notification, format: :json)
