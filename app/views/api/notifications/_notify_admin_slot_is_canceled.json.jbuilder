json.title notification.notification_type
json.description t('.USER_s_reservation_on_the_DATE_was_cancelled_remember_to_generate_a_refund_invoice_if_applicable_html',
                   USER: notification.attached_object.reservation.user.profile.full_name,
                   DATE: I18n.l(notification.attached_object.start_at, format: :long))
json.url notification_url(notification, format: :json)
