json.title notification.notification_type
json.description t('.policy_updated') +
                 "<a href='/#!/privacy-policy>#{t('.click_to_show')}</a>."
json.url notification_url(notification, format: :json)
