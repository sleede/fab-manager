class NotificationCenter
  # send notification to one or several receiver with a type and attached object
  def self.call(type: nil, receiver: nil, attached_object: nil)
    if receiver.respond_to?(:each)
      receiver.each do |user|
        Notification.new.send_notification(type: type, attached_object: attached_object)
                        .to(user)
                        .deliver_later
      end
    else
      Notification.new.send_notification(type: type, attached_object: attached_object)
                      .to(receiver)
                      .deliver_later
    end
  end
end
