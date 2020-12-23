# frozen_string_literal: true

# Periodically checks if a PaymentScheduleItem cames to its due date.
# If this is the case
class PaymentScheduleWorker
  include Sidekiq::Worker

  def perform
    PaymentScheduleItem.where(due_date: [DateTime.current.at_beginning_of_day, DateTime.current.end_of_day], state: 'new').each do |psi|
      # the following depends on the payment method (stripe/check)
      # if stripe:
      # - verify the payment was successful
      #   - if not, alert the admins
      #   - if succeeded, generate the invoice
      # if check:
      # - alert the admins and the user that it is time to bank the check
      # - generate the invoice
      # finally, in any cases, update the psi.state field according to the new status
    end
  end
end
