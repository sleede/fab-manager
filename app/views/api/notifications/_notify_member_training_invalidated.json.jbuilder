# frozen_string_literal: true

json.title notification.notification_type
json.description t('.invalidated', **{ MACHINES: ERB::Util.html_escape(notification.attached_object.machines.map(&:name).join(', ')) })
