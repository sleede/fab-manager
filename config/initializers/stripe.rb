# frozen_string_literal: true

require 'stripe'

Stripe.api_key = Rails.application.secrets.stripe_api_key
Stripe.api_version = '2019-08-14'