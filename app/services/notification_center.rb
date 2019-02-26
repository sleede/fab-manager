# frozen_string_literal: true

# send notification to one or several receiver with a type, an attached object and an optional meta data
class NotificationCenter
  def self.call(type: nil, receiver: nil, attached_object: nil, meta_data: {})
    if receiver.respond_to?(:each)
      receiver.each do |user|
        Notification.new(meta_data: meta_data)
                    .send_notification(type: type, attached_object: attached_object)
                    .to(user)
                    .deliver_later
      end
    else
      Notification.new(meta_data: meta_data)
                  .send_notification(type: type, attached_object: attached_object)
                  .to(receiver)
                  .deliver_later
    end
  end
end
