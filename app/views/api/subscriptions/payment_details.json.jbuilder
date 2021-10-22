# frozen_string_literal: true

json.payment_schedule !@subscription.original_payment_schedule.nil?
json.card @subscription.original_invoice&.paid_by_card?
