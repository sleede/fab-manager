json.title notification.notification_type
json.description t('.your_TRAINING_was_validated_html',
                    TRAINING: notification.attached_object.training.name)
json.url notification_url(notification, format: :json)
