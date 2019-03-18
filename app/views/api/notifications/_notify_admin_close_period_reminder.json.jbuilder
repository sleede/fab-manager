json.title notification.notification_type
if notification.attached_object.class.name == AccountingPeriod.name
  json.description t('warning_last_closed_period_over_1_year', LAST_END: notification.attached_object.end_at)
else
  json.description t('warning_no_closed_periods', FIRST_DATE: notification.attached_object.created_at.to_date)
end
json.url notification_url(notification, format: :json)
