class SubscriptionExpireWorker
  include Sidekiq::Worker

  def perform(expire_in)
    Subscription.where('expired_at >= ?', Time.now.at_beginning_of_day).each do |s|
      if (s.expired_at - expire_in.days).to_date == Time.now.to_date
        if expire_in != 0
          NotificationCenter.call type: 'notify_member_subscription_will_expire_in_7_days',
                                  receiver: s.user,
                                  attached_object: s
          NotificationCenter.call type: 'notify_admin_subscription_will_expire_in_7_days',
                                  receiver: User.admins,
                                  attached_object: s
        else
          NotificationCenter.call type: 'notify_member_subscription_is_expired',
                                  receiver: s.user,
                                  attached_object: s
          NotificationCenter.call type: 'notify_admin_subscription_is_expired',
                                  receiver: User.admins,
                                  attached_object: s
        end
      end
    end
  end
end
