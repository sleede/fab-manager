# frozen_string_literal: true

json.partial! 'api/payment_schedules/payment_schedule_item', item: @payment_schedule_item
if @payment_schedule_item.payment_gateway_object && @payment_schedule_item.state == 'requires_action'
  json.client_secret @payment_schedule_item.payment_intent.client_secret
end
