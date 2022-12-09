# frozen_string_literal: false

# module definition
module Accounting; end

# Provides the routine to build the accounting data and save them in DB
class Accounting::AccountingService
  def initialize
    @currency = ENV.fetch('INTL_CURRENCY') { '' }
    @journal_service = Accounting::AccountingJournalService.new
  end

  # build accounting lines for invoices between the provided dates
  def build(start_date, end_date)
    invoices = Invoice.where('created_at >= ? AND created_at <= ?', start_date, end_date).order('created_at ASC')
    build_from_invoices(invoices)
  end

  # build accounting lines for the provided invoices
  def build_from_invoices(invoices)
    lines = []
    invoices.find_each do |i|
      Rails.logger.debug { "processing invoice #{i.id}..." } unless Rails.env.test?
      lines.concat(generate_lines(i))
    end
    AccountingLine.create!(lines)
  end

  def self.status
    workers = Sidekiq::Workers.new
    workers.each do |_process_id, _thread_id, work|
      return 'building' if work['payload']['class'] == 'AccountingWorker'
    end
    'built'
  end

  private

  def generate_lines(invoice)
    lines = client_lines(invoice) + items_lines(invoice)

    vat = vat_line(invoice)
    lines << vat unless vat.nil?

    fix_rounding_errors(lines)

    lines
  end

  # Generate the lines associated with the provided invoice, for the sales accounts
  def items_lines(invoice)
    lines = []
    %w[Subscription Reservation WalletTransaction StatisticProfilePrepaidPack OrderItem Error].each do |object_type|
      items = invoice.invoice_items.filter { |ii| ii.object_type == object_type }
      items.each do |item|
        lines << line(
          invoice,
          'item',
          @journal_service.sales_journal(object_type),
          Accounting::AccountingCodeService.sales_account(item),
          item.net_amount,
          account_label: Accounting::AccountingCodeService.sales_account(item, type: :label),
          analytical_code: Accounting::AccountingCodeService.sales_account(item, section: :analytical_section)
        )
      end
    end
    lines
  end

  # Generate the "client" lines, which contains the debit to the client account, all taxes included
  def client_lines(invoice)
    lines = []
    invoice.payment_means.each do |details|
      lines << line(
        invoice,
        'client',
        @journal_service.client_journal(details[:means]),
        Accounting::AccountingCodeService.client_account(details[:means]),
        details[:amount],
        account_label: Accounting::AccountingCodeService.client_account(details[:means], type: :label),
        debit_method: :debit_client,
        credit_method: :credit_client
      )
    end
    lines
  end

  # Generate the "VAT" line, which contains the credit to the VAT account, with total VAT amount only
  def vat_line(invoice)
    vat_rate_groups = VatHistoryService.new.invoice_vat(invoice)
    total_vat = vat_rate_groups.values.pluck(:total_vat).sum
    # we do not render the VAT row if it was disabled for this invoice
    return nil if total_vat.zero?

    line(
      invoice,
      'vat',
      @journal_service.vat_journal,
      Accounting::AccountingCodeService.vat_account,
      total_vat,
      account_label: Accounting::AccountingCodeService.vat_account(type: :label)
    )
  end

  # Generate a row of the export, filling the configured columns with the provided values
  def line(invoice, line_type, journal_code, account_code, amount,
           account_label: '', analytical_code: '', debit_method: :debit, credit_method: :credit)
    {
      line_type: line_type,
      journal_code: journal_code,
      date: invoice.created_at,
      account_code: account_code,
      account_label: account_label,
      analytical_code: analytical_code,
      invoice_id: invoice.id,
      invoicing_profile_id: invoice.invoicing_profile_id,
      debit: method(debit_method).call(invoice, amount),
      credit: method(credit_method).call(invoice, amount),
      currency: @currency,
      summary: summary(invoice)
    }
  end

  # Fill the value of the "debit" column: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def debit(invoice, amount)
    invoice.is_a?(Avoir) ? amount : 0
  end

  # Fill the value of the "credit" column: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def credit(invoice, amount)
    invoice.is_a?(Avoir) ? 0 : amount
  end

  # Fill the value of the "debit" column for the client row: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def debit_client(invoice, amount)
    credit(invoice, amount)
  end

  # Fill the value of the "credit" column, for the client row: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def credit_client(invoice, amount)
    debit(invoice, amount)
  end

  # Create a text from the given invoice, matching the accounting software rules for the labels
  def summary(invoice)
    reference = invoice.reference

    items = invoice.subscription_invoice? ? [I18n.t('accounting_summary.subscription_abbreviation')] : []
    if invoice.main_item.object_type == 'Reservation'
      items.push I18n.t("accounting_summary.#{invoice.main_item.object.reservable_type}_reservation_abbreviation")
    end
    items.push I18n.t('accounting_summary.wallet_abbreviation') if invoice.main_item.object_type == 'WalletTransaction'
    items.push I18n.t('accounting_summary.shop_order_abbreviation') if invoice.main_item.object_type == 'OrderItem'

    "#{reference}, #{items.join(' + ')}"
  end

  # In case of rounding errors, fix the balance by adding or removing a cent to the last item line
  # This case should only happen when a coupon has been used.
  def fix_rounding_errors(lines)
    debit_sum = lines.filter { |l| l[:line_type] == 'client' }.pluck(:debit).sum
    credit_sum = lines.filter { |l| l[:line_type] != 'client' }.pluck(:credit).sum

    return if debit_sum == credit_sum

    diff = debit_sum - credit_sum
    fixable_line = lines.filter { |l| l[:line_type] == 'item' }.last
    fixable_line.credit += diff
  end
end
