# frozen_string_literal: true

# Periodically checks if a PaymentScheduleItem cames to its due date.
# If this is the case
class PaymentScheduleItemWorker
  include Sidekiq::Worker

  def perform(record_id = nil)
    p "WORKER CURRENCY_LOCALE=#{CURRENCY_LOCALE}"
    # if record_id
    #   psi = PaymentScheduleItem.find(record_id)
    #   check_item(psi)
    # else
    #   PaymentScheduleItem.where.not(state: 'paid').where('due_date < ?', Time.current).each do |item|
    #     check_item(item)
    #   end
    # end
  end

  # @param psi [PaymentScheduleItem]
  def check_item(psi)
    # the following depends on the payment method (card/check)
    if psi.payment_schedule.payment_method == 'card'
      ### Cards
      PaymentGatewayService.new.process_payment_schedule_item(psi)
    elsif psi.state == 'new'
      ### Check/Bank transfer (only new deadlines, to prevent spamming)
      NotificationCenter.call type: "notify_admin_payment_schedule_#{psi.payment_schedule.payment_method}_deadline",
                              receiver: User.admins_and_managers,
                              attached_object: psi
      psi.update(state: 'pending')
    end
  rescue StandardError => e
    Rails.logger.debug(e.backtrace)
    psi.update(state: 'error')
  end
end
