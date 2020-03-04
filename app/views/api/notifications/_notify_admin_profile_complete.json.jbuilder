# frozen_string_literal: true

default_provider = AuthProvider.find_by(providable_type: DatabaseProvider.name).name
json.title notification.notification_type
json.description t('.account_imported_from_PROVIDER_UID_has_completed_its_information_html',
                   PROVIDER: notification.attached_object.provider || default_provider,
                   UID: notification.attached_object.uid || notification.attached_object.id)
json.url notification_url(notification, format: :json)
