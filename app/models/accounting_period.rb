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
    Invoice.where('created_at >= :start_date AND CAST(created_at AS DATE) <= :end_date', start_date: start_at, end_date: end_at)
  end

  def invoices_with_vat(invoices)
    invoices.map do |i|
      if i.type == 'Avoir'
        { invoice: i, vat_rate: vat_rate(i.avoir_date) }
      else
        { invoice: i, vat_rate: vat_rate(i.created_at) }
      end
    end
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

  def vat_rate(date)
    @vat_rates = vat_history if @vat_rates.nil?

    first_rate = @vat_rates.first
    return first_rate[:rate] if date < first_rate[:date]

    @vat_rates.each do |h|
      return h[:rate] if h[:date] <= date
    end
  end

  private

  def vat_history
    key_dates = []
    Setting.find_by(name: 'invoice_VAT-rate').history_values.each do |rate|
      key_dates.push(date: rate.created_at, rate: (rate.value.to_i / 100.0))
    end
    Setting.find_by(name: 'invoice_VAT-active').history_values.each do |v|
      key_dates.push(date: v.created_at, rate: 0) if v.value == 'false'
    end
    key_dates.sort_by { |k| k[:date] }
  end

  def to_json_archive(invoices)
    previous_file = previous_period&.archive_file
    code_checksum = Checksum.code
    last_archive_checksum = previous_file ? Checksum.file(previous_file) : nil
    ApplicationController.new.view_context.render(
      partial: 'archive/accounting',
      locals: {
        invoices: invoices_with_vat(invoices),
        period_total: period_total,
        perpetual_total: perpetual_total,
        period_footprint: footprint,
        code_checksum: code_checksum,
        last_archive_checksum: last_archive_checksum,
        previous_file: previous_file,
        software_version: Version.current,
        date: Time.now.iso8601
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

  def price_without_taxe(invoice)
    invoice[:invoice].total - (invoice[:invoice].total * invoice[:vat_rate])
  end

  def compute_totals
    period_invoices = invoices_with_vat(invoices.where(type: nil))
    period_avoirs = invoices_with_vat(invoices.where(type: 'Avoir'))
    self.period_total = (period_invoices.map(&method(:price_without_taxe)).reduce(:+) || 0) -
                        (period_avoirs.map(&method(:price_without_taxe)).reduce(:+) || 0)

    all_invoices = invoices_with_vat(Invoice.where('CAST(created_at AS DATE) <= :end_date AND type IS NULL', end_date: end_at))
    all_avoirs = invoices_with_vat(Invoice.where("CAST(created_at AS DATE) <= :end_date AND type = 'Avoir'", end_date: end_at))
    self.perpetual_total = (all_invoices.map(&method(:price_without_taxe)).reduce(:+) || 0) -
                           (all_avoirs.map(&method(:price_without_taxe)).reduce(:+) || 0)
    self.footprint = compute_footprint
  end

  def compute_footprint
    columns = AccountingPeriod.columns.map(&:name)
                              .delete_if { |c| %w[id footprint created_at updated_at].include? c }

    sha256 = Digest::SHA256.new
    sha256.hexdigest "#{columns.map { |c| self[c] }.join}#{previous_period ? previous_period.footprint : ''}"
  end
end
