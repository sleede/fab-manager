# frozen_string_literal: false

# Provides the routine to export the accounting data to an external accounting software
class AccountingExportService
  include ActionView::Helpers::NumberHelper

  attr_reader :encoding, :format, :separator, :journal_code, :date_format, :columns, :vat_service, :decimal_separator, :label_max_length,
              :export_zeros

  def initialize(columns, encoding: 'UTF-8', format: 'CSV', separator: ';')
    @encoding = encoding
    @format = format
    @separator = separator
    @decimal_separator = ','
    @date_format = '%d/%m/%Y'
    @label_max_length = 50
    @export_zeros = false
    @journal_code = Setting.find_by(name: 'accounting_journal_code')&.value || ''
    @date_format = date_format
    @columns = columns
    @vat_service = VatHistoryService.new
  end

  def set_options(decimal_separator: ',', date_format: '%d/%m/%Y', label_max_length: 50, export_zeros: false)
    @decimal_separator = decimal_separator
    @date_format = date_format
    @label_max_length = label_max_length
    @export_zeros = export_zeros
  end

  def export(start_date, end_date, file)
    # build CVS content
    content = header_row
    invoices = Invoice.where('created_at >= ? AND created_at <= ?', start_date, end_date).order('created_at ASC')
    invoices = invoices.where('total > 0') unless export_zeros
    invoices.each do |i|
      content << generate_rows(i)
    end

    # write content to file
    File.open(file, "w:#{encoding}") { |f| f.puts content.encode(encoding, invalid: :replace, undef: :replace) }
  end

  private

  def header_row
    row = ''
    columns.each do |column|
      row << I18n.t("accounting_export.#{column}") << separator
    end
    "#{row}\n"
  end

  def generate_rows(invoice)
    vat = vat_row(invoice)
    "#{client_row(invoice)}\n" \
      "#{items_rows(invoice)}" \
      "#{vat.nil? ? '' : "#{vat}\n"}"
  end

  # Generate the "subscription" and "reservation" rows associated with the provided invoice
  def items_rows(invoice)
    rows = invoice.subscription_invoice? ? "#{subscription_row(invoice)}\n" : ''
    if invoice.invoiced_type == 'Reservation'
      invoice.invoice_items.each do |item|
        rows << "#{reservation_row(invoice, item)}\n"
      end
    elsif invoice.invoiced_type == 'WalletTransaction'
      rows << "#{wallet_row(invoice)}\n"
    end
    rows
  end

  # Generate the "client" row, which contains the debit to the client account, all taxes included
  def client_row(invoice)
    total = invoice.total / 100.00
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account(invoice, :client)
      when 'account_label'
        row << account(invoice, :client, :label)
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << label(invoice)
      when 'debit_origin'
        row << debit_client(invoice, total)
      when 'credit_origin'
        row << credit_client(invoice, total)
      when 'debit_euro'
        row << debit_client(invoice, total)
      when 'credit_euro'
        row << credit_client(invoice, total)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Generate the "reservation" row, which contains the credit to the reservation account, all taxes excluded
  def reservation_row(invoice, item)
    wo_taxes_coupon = item.net_amount / 100.00
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account(invoice, :reservation)
      when 'account_label'
        row << account(invoice, :reservation, :label)
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << ''
      when 'debit_origin'
        row << debit(invoice, wo_taxes_coupon)
      when 'credit_origin'
        row << credit(invoice, wo_taxes_coupon)
      when 'debit_euro'
        row << debit(invoice, wo_taxes_coupon)
      when 'credit_euro'
        row << credit(invoice, wo_taxes_coupon)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Generate the "subscription" row, which contains the credit to the subscription account, all taxes excluded
  def subscription_row(invoice)
    subscription_item = invoice.invoice_items.select(&:subscription).first
    wo_taxes_coupon = subscription_item.net_amount / 100.00
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account(invoice, :subscription)
      when 'account_label'
        row << account(invoice, :subscription, :label)
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << ''
      when 'debit_origin'
        row << debit(invoice, wo_taxes_coupon)
      when 'credit_origin'
        row << credit(invoice, wo_taxes_coupon)
      when 'debit_euro'
        row << debit(invoice, wo_taxes_coupon)
      when 'credit_euro'
        row << credit(invoice, wo_taxes_coupon)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Generate the "wallet" row, which contains the credit to the wallet account, all taxes excluded
  # This applies to wallet crediting, when an Avoir is generated at this time
  def wallet_row(invoice)
    row = ''
    price = invoice.invoice_items.first.net_amount / 100.00
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account(invoice, :wallet)
      when 'account_label'
        row << account(invoice, :wallet, :label)
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << ''
      when 'debit_origin'
        row << debit(invoice, price)
      when 'credit_origin'
        row << credit(invoice, price)
      when 'debit_euro'
        row << debit(invoice, price)
      when 'credit_euro'
        row << credit(invoice, price)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Generate the "VAT" row, which contains the credit to the VAT account, with VAT amount only
  def vat_row(invoice)
    rate = vat_service.invoice_vat(invoice)
    # we do not render the VAT row if it was disabled for this invoice
    return nil if rate.zero?

    vat = invoice.invoice_items.map(&:vat).map(&:to_i).reduce(:+) / 100.00
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account(invoice, :vat)
      when 'account_label'
        row << account(invoice, :vat, :label)
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << ''
      when 'debit_origin'
        row << debit(invoice, vat)
      when 'credit_origin'
        row << credit(invoice, vat)
      when 'debit_euro'
        row << debit(invoice, vat)
      when 'credit_euro'
        row << credit(invoice, vat)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Get the account code (or label) for the given invoice and the specified line type (client, vat, subscription or reservation)
  def account(invoice, account, type = :code)
    res = case account
          when :client
            means = invoice.paid_with_stripe? ? 'card' : 'site'
            Setting.find_by(name: "accounting_#{means}_client_#{type}")&.value
          when :vat
            Setting.find_by(name: "accounting_VAT_#{type}")&.value
          when :subscription
            if invoice.subscription_invoice?
              Setting.find_by(name: "accounting_subscription_#{type}")&.value
            else
              puts "WARN: Invoice #{invoice.id} has no subscription"
            end
          when :reservation
            if invoice.invoiced_type == 'Reservation'
              Setting.find_by(name: "accounting_#{invoice.invoiced.reservable_type}_#{type}")&.value
            else
              puts "WARN: Invoice #{invoice.id} has no reservation"
            end
          when :wallet
            if invoice.invoiced_type == 'WalletTransaction'
              Setting.find_by(name: "accounting_wallet_#{type}")&.value
            else
              puts "WARN: Invoice #{invoice.id} is not a wallet credit"
            end
          else
            puts "Unsupported account #{account}"
          end
    res || ''
  end

  # Fill the value of the "debit" column: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def debit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? format_number(amount) : '0'
  end

  # Fill the value of the "credit" column: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def credit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? '0' : format_number(amount)
  end

  # Fill the value of the "debit" column for the client row: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def debit_client(invoice, amount)
    credit(invoice, amount)
  end

  # Fill the value of the "credit" column, for the client row: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def credit_client(invoice, amount)
    debit(invoice, amount)
  end

  # Format the given number as a string, using the configured separator
  def format_number(num)
    number_to_currency(num, unit: '', separator: decimal_separator, delimiter: '', precision: 2)
  end

  # Create a text from the given invoice, matching the accounting software rules for the labels
  def label(invoice)
    name = "#{invoice.invoicing_profile.last_name} #{invoice.invoicing_profile.first_name}".tr separator, ''
    reference = invoice.reference
    items = invoice.subscription_invoice? ? [I18n.t('accounting_export.subscription')] : []
    items.push I18n.t("accounting_export.#{invoice.reservation.reservable_type}_reservation") if invoice.invoiced_type == 'Reservation'
    summary = items.join(' + ')
    res = "#{reference}, #{summary}"
    "#{name.truncate(label_max_length - res.length)}, #{res}"
  end
end
