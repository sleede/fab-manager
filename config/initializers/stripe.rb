require "stripe"

Stripe.api_key = Rails.application.secrets.stripe_api_key
Stripe.api_version = "2015-10-16"