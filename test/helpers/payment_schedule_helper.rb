# frozen_string_literal: true

# Provides methods to help testing payment schedules
module PaymentScheduleHelper
  # Force the payment schedule generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param schedule [PaymentSchedule]
  def assert_schedule_pdf(schedule)
    assert_not_nil schedule, 'Schedule was not created'

    generate_schedule_pdf(schedule)

    assert File.exist?(schedule.file), 'Schedule PDF was not generated'

    File.delete(schedule.file)
  end

  # @param customer [User]
  # @param operator [User]
  # @return [PaymentSchedule] saved
  def sample_schedule(customer, operator)
    plan = plans(:plan_schedulable)
    subscription = Subscription.new(plan: plan, statistic_profile_id: customer.statistic_profile, start_at: Time.current)
    subscription.save
    options = { payment_method: '' }
    unless operator.privileged?
      options = { payment_method: 'card', payment_id: 'pi_3LpALs2sOmf47Nz91QyFI7nP', payment_type: 'Stripe::PaymentIntent' }
    end
    schedule = PaymentScheduleService.new.create([subscription], 113_600, customer, operator: operator, **options)
    schedule.save
    first_item = schedule.ordered_items.first
    PaymentScheduleService.new.generate_invoice(first_item, **options)
    first_item.update(state: 'paid', payment_method: operator.privileged? ? 'check' : 'card')
    schedule
  end

  private

  def generate_schedule_pdf(schedule)
    schedule_worker = PaymentScheduleWorker.new
    schedule_worker.perform(schedule.id)
  end
end
