# frozen_string_literal: true

require 'payment/helper'

# Stripe payement gateway
module Stripe; end

## Provides various methods around the Stripe payment gateway
class Stripe::Helper < Payment::Helper
  class << self
    ## Is the Stripe gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'stripe'

      res = true
      %w[stripe_public_key stripe_secret_key stripe_currency].each do |pz_setting|
        res = false if Setting.get(pz_setting).blank?
      end
      res
    end

    def human_error(error)
      message = error.message
      case error.code
      when 'amount_too_small'
        message.match(/\d+\.\d+\s\w+/) do |res|
          message = I18n.t('errors.messages.gateway_amount_too_small', **{ AMOUNT: res })
        end
      when 'amount_too_large'
        message.match(/\d+\.\d+\s\w+/) do |res|
          message = I18n.t('errors.messages.gateway_amount_too_large', **{ AMOUNT: res })
        end
      else
        message = I18n.t('errors.messages.gateway_error', **{ MESSAGE: message })
      end
      message
    end
  end
end
