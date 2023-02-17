# frozen_string_literal: true

# Handle most of the emails sent by the platform. Triggered by notifications
class NotificationsMailer < BaseMailer
  after_action :mark_notification_as_send

  def send_mail_by(notification)
    @notification = notification
    @recipient = notification.receiver
    @attached_object = notification.attached_object

    unless respond_to?(notification.notification_type)
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{notification.notification_type}                                                # def notify_admin_when_project_published
          mail to: @recipient.email,                                                         #   mail to: @recipient.email,
               subject: t('notifications_mailer.#{notification.notification_type}.subject'), #   subject: t('notifications_mailer.notify_admin_when_project_published.subject'),
               template_name: '#{notification.notification_type}',                           #   template_name: 'notify_admin_when_project_published',
               content_type: 'text/html'                                                     #   content_type: 'text/html'
        end                                                                                  # end
      RUBY
    end

    send(notification.notification_type)
  rescue StandardError => e
    Rails.logger.error "[NotificationsMailer] notification cannot be sent: #{e}"
  end

  def notify_user_when_invoice_ready
    attachments[@attached_object.filename] = File.read(@attached_object.file)
    mail(to: @recipient.email,
         subject: t('notifications_mailer.notify_member_invoice_ready.subject'),
         template_name: 'notify_member_invoice_ready')
  end

  def notify_user_when_avoir_ready
    attachments[@attached_object.filename] = File.read(@attached_object.file)
    mail(to: @recipient.email,
         subject: t('notifications_mailer.notify_member_avoir_ready.subject'),
         template_name: 'notify_member_avoir_ready')
  end

  def notify_user_when_payment_schedule_ready
    attachments[@attached_object.filename] = File.read(@attached_object.file)
    mail(to: @recipient.email,
         subject: t('notifications_mailer.notify_member_payment_schedule_ready.subject'),
         template_name: 'notify_member_payment_schedule_ready')
  end

  def notify_member_create_reservation
    attachments[@attached_object.ics_filename] = @attached_object.to_ics.encode(Encoding::UTF_8)
    mail(to: @recipient.email,
         subject: t('notifications_mailer.notify_member_create_reservation.subject'),
         template_name: 'notify_member_create_reservation')
  end

  private

  def mark_notification_as_send
    @notification.mark_as_send unless @notification.is_send
  end
end
