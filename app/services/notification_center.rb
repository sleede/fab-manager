# frozen_string_literal: true

# send notification to one or several receiver with a type, an attached object and an optional meta data
class NotificationCenter
  def self.call(type: nil, receiver: nil, attached_object: nil, meta_data: {})
    receiver = [receiver] unless receiver.respond_to?(:each)
    receiver.each do |user|
      Notification.new(
        meta_data: meta_data,
        attached_object: attached_object,
        receiver: user,
        notification_type: NotificationType.find_by(name: type)
      )
                  .deliver_later
    end
  end
end
