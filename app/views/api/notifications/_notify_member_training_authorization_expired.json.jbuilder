# frozen_string_literal: true

json.title notification.notification_type
json.description t('.training_authorization_revoked', **{ MACHINES: ERB::Util.html_escape(notification.attached_object.machines.map(&:name).join(', ')) })
