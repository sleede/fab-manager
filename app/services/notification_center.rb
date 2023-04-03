# frozen_string_literal: true

# send notification to one or several receiver with a type, an attached object and an optional meta data
class NotificationCenter
  class << self
    def call(type: nil, receiver: nil, attached_object: nil, meta_data: {})
      return if prevent_notify?(type: type, attached_object: attached_object)

      receiver = [receiver] unless receiver.respond_to?(:each)
      notification_type = NotificationType.find_by(name: type)

      receiver.each do |user|
        Notification.new(
          meta_data: meta_data,
          attached_object: attached_object,
          receiver: user,
          notification_type: notification_type
        )
                    .deliver_with_preferences(user, notification_type)
      end
    end

    private

    # In some very special cases, we do not want the notification to be created at all
    # @param type [String]
    # @param attached_object [ApplicationRecord]
    # @return [Boolean]
    def prevent_notify?(type: nil, attached_object: nil)
      if type == 'notify_user_when_invoice_ready'
        item = attached_object.main_item
        return true if item.object_type == 'Error' && item.object_id == 1
      end

      false
    end
  end
end
