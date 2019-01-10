# frozen_string_literal: true

# AccountingPeriod is a period of N days (N > 0) which as been closed by an admin
# to prevent writing new accounting lines (invoices & refunds) during this period of time.
class AccountingPeriod < ActiveRecord::Base
  before_destroy { false }
  before_update { false }
  after_create :archive_closed_data

  validates :start_at, :end_at, :closed_at, :closed_by, presence: true
  validates_with DateRangeValidator
  validates_with PeriodOverlapValidator

  def delete
    false
  end

  def archive_file
    dir = 'accounting'

    # create directory if it doesn't exists (accounting)
    FileUtils.mkdir_p dir
    "#{dir}/#{start_at.iso8601}_#{end_at.iso8601}.json"
  end

  private

  def to_json_archive(invoices)
    ApplicationController.new.view_context.render(
      partial: 'archive/accounting',
      locals: { invoices: invoices },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  def archive_closed_data
    data = Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start_at, end_date: end_at)
                  .includes(:invoice_items)
    File.write(archive_file, to_json_archive(data))
  end
end
