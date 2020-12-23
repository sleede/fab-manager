# frozen_string_literal: true

# Periodically checks if a PaymentScheduleItem cames to its due date.
# If this is the case
class PaymentScheduleItemWorker
  include Sidekiq::Worker

  def perform
    PaymentScheduleItem.where(due_date: [DateTime.current.at_beginning_of_day, DateTime.current.end_of_day], state: 'new').each do |psi|
      # the following depends on the payment method (stripe/check)
      if psi.payment_schedule.payment_method == 'stripe'
        # TODO, if stripe:
        # - verify the payment was successful
        #   - if not, alert the admins
        #   - if succeeded, generate the invoice
      else
        # TODO, if check:
        # - alert the admins and the user that it is time to bank the check
        # - generate the invoice
      end
      # TODO, finally, in any cases, update the psi.state field according to the new status
    end
  end
end
