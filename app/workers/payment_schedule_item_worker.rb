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
    # the following depends on the payment method (stripe/check)
    if psi.payment_schedule.payment_method == 'stripe'
      ### Stripe
      stripe_key = Setting.get('stripe_secret_key')
      stp_subscription = Stripe::Subscription.retrieve(psi.payment_schedule.stp_subscription_id, api_key: stripe_key)
      stp_invoice = Stripe::Invoice.retrieve(stp_subscription.latest_invoice, api_key: stripe_key)
      if stp_invoice.status == 'paid'
        ##### Stripe / Successfully paid
        PaymentScheduleService.new.generate_invoice(psi, stp_invoice)
        psi.update_attributes(state: 'paid', payment_method: 'stripe', stp_invoice_id: stp_invoice.id)
      elsif stp_subscription.status == 'past_due' || stp_invoice.status == 'open'
        ##### Stripe / Payment error
        NotificationCenter.call type: 'notify_admin_payment_schedule_failed',
                                receiver: User.admins_and_managers,
                                attached_object: psi
        NotificationCenter.call type: 'notify_member_payment_schedule_failed',
                                receiver: psi.payment_schedule.user,
                                attached_object: psi
        stp_payment_intent = Stripe::PaymentIntent.retrieve(stp_invoice.payment_intent, api_key: stripe_key)
        psi.update_attributes(state: stp_payment_intent.status,
                              stp_invoice_id: stp_invoice.id,
                              client_secret: stp_payment_intent.client_secret)
      else
        psi.update_attributes(state: 'error')
      end
    else
      ### Check
      NotificationCenter.call type: 'notify_admin_payment_schedule_check_deadline',
                              receiver: User.admins_and_managers,
                              attached_object: psi
      psi.update_attributes(state: 'pending')
    end
  end
end
