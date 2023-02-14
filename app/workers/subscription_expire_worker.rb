# frozen_string_literal: true

# Notify users about the expiration of their subscription
class SubscriptionExpireWorker
  include Sidekiq::Worker

  def perform(expire_in)
    Subscription.where('expiration_date >= ?', Time.current.at_beginning_of_day).each do |s|
      if (s.expired_at - expire_in.days).to_date == Time.current.to_date
        if expire_in.zero?
          NotificationCenter.call type: 'notify_member_subscription_is_expired',
                                  receiver: s.user,
                                  attached_object: s
          NotificationCenter.call type: 'notify_admin_subscription_is_expired',
                                  receiver: User.admins_and_managers,
                                  attached_object: s
        else
          NotificationCenter.call type: 'notify_member_subscription_will_expire_in_7_days',
                                  receiver: s.user,
                                  attached_object: s
          NotificationCenter.call type: 'notify_admin_subscription_will_expire_in_7_days',
                                  receiver: User.admins_and_managers,
                                  attached_object: s
        end
      end
    end
  end
end
