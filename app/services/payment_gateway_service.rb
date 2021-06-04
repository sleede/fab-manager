# frozen_string_literal: true

require 'stripe/helper'
require 'pay_zen/helper'

# create remote items on currently active payment gateway
class PaymentGatewayService
  def initialize
    service = if Stripe::Helper.enabled?
                require 'stripe/service'
                Stripe::Service
              elsif PayZen::Helper.enabled?
                require 'pay_zen/service'
                PayZen::Service
              else
                require 'payment/service'
                Payment::Service
              end
    @gateway = service.new
  end

  def create_subscription(payment_schedule, gateway_object_id)
    @gateway.create_subscription(payment_schedule, gateway_object_id)
  end

  def create_coupon(coupon_id)
    @gateway.create_coupon(coupon_id)
  end

  def delete_coupon(coupon_id)
    @gateway.delete_coupon(coupon_id)
  end

  def create_or_update_product(klass, id)
    @gateway.create_or_update_product(klass, id)
  end

  def process_payment_schedule_item(payment_schedule_item)
    gateway = service_for_payment_schedule(payment_schedule_item.payment_schedule)
    gateway.process_payment_schedule_item(payment_schedule_item)
  end

  def pay_payment_schedule_item(payment_schedule_item)
    gateway = service_for_payment_schedule(payment_schedule_item.payment_schedule)
    gateway.pay_payment_schedule_item(payment_schedule_item)
  end

  private

  def service_for_payment_schedule(payment_schedule)
    service = case payment_schedule.gateway_subscription.klass
              when /^PayZen::/
                require 'pay_zen/service'
                PayZen::Service
              when /^Stripe::/
                require 'stripe/service'
                Stripe::Service
              else
                require 'payment/service'
                Payment::Service
              end
    service.new
  end
end
