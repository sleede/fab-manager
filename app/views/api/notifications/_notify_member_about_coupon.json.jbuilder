json.title notification.notification_type
if notification.attached_object.type == 'percent_off'
  json.description t('.enjoy_a_discount_of_PERCENT_with_code_CODE',
                     PERCENT: notification.attached_object.percent_off,
                     CODE: notification.attached_object.code)
else
  json.description t('.enjoy_a_discount_of_AMOUNT_with_code_CODE',
                     AMOUNT: number_to_currency(notification.attached_object.amount_off / 100.00),
                     CODE: notification.attached_object.code)
end
json.url notification_url(notification, format: :json)
