# frozen_string_literal: true

# Services around subscriptions
module Subscriptions; end

# Expire the given subscription
class Subscriptions::ExpireService
  class << self
    # @param subscription [Subscription]
    def call(subscription)
      expiration = Time.current
      if subscription.expired?
        false
      else
        subscription.update_columns(expiration_date: expiration, canceled_at: expiration) # rubocop:disable Rails/SkipsModelValidations
        subscription.offer_days.find_each do |od|
          od.update(start_at: expiration, end_at: expiration)
        end
        notify_admin_subscription_canceled(subscription)
        notify_member_subscription_canceled(subscription)
        true
      end
    end

    private

    # @param subscription [Subscription]
    def notify_admin_subscription_canceled(subscription)
      NotificationCenter.call type: 'notify_admin_subscription_canceled',
                              receiver: User.admins_and_managers,
                              attached_object: subscription
    end

    # @param subscription [Subscription]
    def notify_member_subscription_canceled(subscription)
      NotificationCenter.call type: 'notify_member_subscription_canceled',
                              receiver: subscription.user,
                              attached_object: subscription
    end
  end
end
