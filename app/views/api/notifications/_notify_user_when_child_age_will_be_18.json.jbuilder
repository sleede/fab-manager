# frozen_string_literal: true

json.title notification.notification_type
json.description t('.child_age_will_be_18_years_ago',
                   NAME: notification.attached_object.full_name,
                   DATE: I18n.l(notification.attached_object.birthday, format: :default))
