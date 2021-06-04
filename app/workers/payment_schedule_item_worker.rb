# frozen_string_literal: true

# Periodically checks if a PaymentScheduleItem cames to its due date.
# If this is the case
class PaymentScheduleItemWorker
  include Sidekiq::Worker

  def perform(record_id = nil)
    if record_id
      psi = PaymentScheduleItem.find(record_id)
      check_item(psi)
    else
      PaymentScheduleItem.where.not(state: 'paid').where('due_date < ?', DateTime.current).each do |psi|
        check_item(psi)
      end
    end
  end

  def check_item(psi)
    # the following depends on the payment method (card/check)
    if psi.payment_schedule.payment_method == 'card'
      ### Cards
      PaymentGatewayService.new.process_payment_schedule_item(psi)
    elsif psi.state == 'new'
      ### Check (only new deadlines, to prevent spamming)
      NotificationCenter.call type: 'notify_admin_payment_schedule_check_deadline',
                              receiver: User.admins_and_managers,
                              attached_object: psi
      psi.update_attributes(state: 'pending')
    end
  rescue StandardError
    psi.update_attributes(state: 'error')
  end
end
