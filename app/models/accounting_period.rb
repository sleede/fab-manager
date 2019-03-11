# frozen_string_literal: true

require 'checksum'
require 'version'

# AccountingPeriod is a period of N days (N > 0) which as been closed by an admin
# to prevent writing new accounting lines (invoices & refunds) during this period of time.
class AccountingPeriod < ActiveRecord::Base
  before_destroy { false }
  before_update { false }
  before_create :compute_totals
  after_create :archive_closed_data

  validates :start_at, :end_at, :closed_at, :closed_by, presence: true
  validates_with DateRangeValidator
  validates_with PeriodOverlapValidator
  validates_with PeriodIntegrityValidator

  def delete
    false
  end

  def invoices
    Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start_at, end_date: end_at)
  end

  def archive_file
    dir = 'accounting'

    # create directory if it doesn't exists (accounting)
    FileUtils.mkdir_p dir
    "#{dir}/#{start_at.iso8601}_#{end_at.iso8601}.json"
  end

  def check_footprint
    footprint == compute_footprint
  end

  private

  def to_json_archive(invoices)
    previous_file = previous_period&.archive_file
    code_checksum = Checksum.code
    last_archive_checksum = previous_file ? Checksum.file(previous_file) : nil
    ApplicationController.new.view_context.render(
      partial: 'archive/accounting',
      locals: {
        invoices: invoices,
        period_total: period_total,
        perpetual_total: perpetual_total,
        period_footprint: footprint,
        code_checksum: code_checksum,
        last_archive_checksum: last_archive_checksum,
        previous_file: previous_file,
        software_version: Version.current
      },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  def previous_period
    AccountingPeriod.where('closed_at < ?', closed_at).order(closed_at: :desc).limit(1).last
  end

  def archive_closed_data
    data = invoices.includes(:invoice_items)
    File.write(archive_file, to_json_archive(data))
  end

  def compute_totals
    self.period_total = invoices.all.map(&:total).reduce(:+)
    self.perpetual_total = Invoice.where('created_at < :end_date', end_date: end_at).all.map(&:total).reduce(:+)
    self.footprint = compute_footprint
  end

  def compute_footprint
    columns = AccountingPeriod.columns.map(&:name)
                              .delete_if { |c| %w[footprint updated_at].include? c }

    sha256 = Digest::SHA256.new
    sha256.hexdigest "#{columns.map { |c| self[c] }.join}#{previous_period ? previous_period.footprint : ''}"
  end
end
