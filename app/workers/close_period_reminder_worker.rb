class ClosePeriodReminderWorker
  include Sidekiq::Worker

  def perform
    last_period = AccountingPeriod.order(closed_at: :desc).limit(1).last
    return if Invoice.count == 0 || (last_period && last_period.end_at > (Time.current - 1.year))

    NotificationCenter.call type: 'notify_admin_close_period_reminder',
                            receiver: User.admins,
                            attached_object: last_period || Invoice.order(:created_at).first
  end
end
