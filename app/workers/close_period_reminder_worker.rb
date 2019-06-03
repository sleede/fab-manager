class ClosePeriodReminderWorker
  include Sidekiq::Worker

  def perform
    return if Invoice.count.zero?

    last_period = AccountingPeriod.order(closed_at: :desc).limit(1).last
    first_invoice = Invoice.order(created_at: :asc).limit(1).last
    return if !last_period && first_invoice.created_at > (Time.current - 1.year)
    return if last_period && last_period.end_at > (Time.current - 1.year)

    NotificationCenter.call type: 'notify_admin_close_period_reminder',
                            receiver: User.admins,
                            attached_object: last_period || Invoice.order(:created_at).first
  end
end
