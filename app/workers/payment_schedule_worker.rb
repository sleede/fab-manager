# frozen_string_literal: true

# Generates the PDF Document associated with the provided payment schedule, and send it to the customer
# If this is the case
class PaymentScheduleWorker
  include Sidekiq::Worker

  def perform(payment_schedule_id)
    # generate a payment schedule document
    ps = PaymentSchedule.find(payment_schedule_id)
    pdf = ::Pdf::PaymentSchedule.new(ps).render

    # save the file on the disk
    File.binwrite(ps.file, pdf)

    # notify user, send schedule document by email
    NotificationCenter.call type: 'notify_user_when_payment_schedule_ready',
                            receiver: ps.user,
                            attached_object: ps
  end
end
