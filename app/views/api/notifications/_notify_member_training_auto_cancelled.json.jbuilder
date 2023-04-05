# frozen_string_literal: true

json.title notification.notification_type
json.description "#{t('.auto_cancelled_training', **{
                        TRAINING: notification.attached_object.reservation.reservable.name,
                        DATE: I18n.l(notification.attached_object.slot.start_at.to_date)
                      })} #{notification.meta_data['auto_refund'] ? t('.auto_refund') : ''}"
