# frozen_string_literal: true

# Periodically checks if a PaymentScheduleItem cames to its due date.
# If this is the case
class PaymentScheduleItemWorker
  include Sidekiq::Worker

  def perform
    PaymentScheduleItem.where(due_date: [DateTime.current.at_beginning_of_day, DateTime.current.end_of_day], state: 'new').each do |psi|
      # the following depends on the payment method (stripe/check)
      if psi.payment_schedule.payment_method == 'stripe'
        ### Stripe
        stripe_key = Setting.get('stripe_secret_key')
        stp_suscription = Stripe::Subscription.retrieve(psi.payment_schedule.stp_subscription_id, api_key: stripe_key)
        stp_invoice = Stripe::Invoice.retrieve(stp_suscription.latest_invoice, api_key: stripe_key)
        if stp_invoice.status == 'paid'
          ##### Stripe / Successfully paid
          PaymentScheduleService.new.generate_invoice(psi, stp_invoice)
          psi.update_attributes(state: 'paid')
        else
          ##### Stripe / Payment error
          NotificationCenter.call type: 'notify_admin_payment_schedule_failed',
                                  receiver: User.admins_and_managers,
                                  attached_object: psi
          NotificationCenter.call type: 'notify_member_payment_schedule_failed',
                                  receiver: psi.payment_schedule.user,
                                  attached_object: psi
          psi.update_attributes(state: 'pending')
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
end
