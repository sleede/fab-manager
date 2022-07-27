# frozen_string_literal: true

# This worker perform various requests to the Stripe API (payment service)
class SyncObjectsOnStripeWorker
  require 'stripe/service'
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, on_conflict: :reject, queue: :stripe

  def perform(notify_user_id = nil)
    Rails.logger.info 'We create all non-existing customers on stripe. This may take a while...'
    total = User.online_payers.count
    User.online_payers.each_with_index do |member, index|
      Rails.logger.info "#{index} / #{total}"
      begin
        stp_customer = member.payment_gateway_object&.gateway_object&.retrieve
        StripeWorker.new.create_stripe_customer(member.id) if stp_customer.nil? || stp_customer[:deleted]
      rescue Stripe::InvalidRequestError
        begin
          StripeWorker.new.create_stripe_customer(member.id)
        rescue Stripe::InvalidRequestError => e
          Rails.logger.error "Unable to create the customer #{member.id} do to a Stripe error: #{e}"
        end
      end
    end

    Rails.logger.info 'We create all non-existing coupons on stripe. This may take a while...'
    total = Coupon.all.count
    Coupon.all.each_with_index do |coupon, index|
      Rails.logger.info "#{index} / #{total}"
      Stripe::Coupon.retrieve(coupon.code, api_key: Setting.get('stripe_secret_key'))
    rescue Stripe::InvalidRequestError
      begin
        Stripe::Service.new.create_coupon(coupon.id)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Unable to create coupon #{coupon.code} on stripe: #{e}"
      end
    end

    w = StripeWorker.new
    [Machine, Training, Space, Plan].each do |klass|
      Rails.logger.info "We create all non-existing #{klass} on stripe. This may take a while..."
      total = klass.all.count
      klass.all.each_with_index do |item, index|
        Rails.logger.info "#{index} / #{total}"
        w.perform(:create_or_update_stp_product, klass.name, item.id)
      end
    end
    Rails.logger.info 'Sync is done'
    return unless notify_user_id

    Rails.logger.info "Notify user #{notify_user_id}"
    user = User.find(notify_user_id)
    NotificationCenter.call type: :notify_admin_objects_stripe_sync,
                            receiver: user,
                            attached_object: user
  end
end
