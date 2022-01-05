# frozen_string_literal: true

json.title notification.notification_type
json.description t('.schedule_deadline', DATE: I18n.l(notification.attached_object.due_date.to_date),
                                         REFERENCE: notification.attached_object.payment_schedule.reference)
