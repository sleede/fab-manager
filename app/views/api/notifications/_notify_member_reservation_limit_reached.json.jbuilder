# frozen_string_literal: true

json.title notification.notification_type
json.description t('.limit_reached',
                   HOURS: notification.attached_object.limit,
                   ITEM: ERB::Util.html_escape(notification.attached_object.limitable.name),
                   DATE: I18n.l(notification.get_meta_data(:date).to_date))
