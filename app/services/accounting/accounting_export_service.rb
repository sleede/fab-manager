# frozen_string_literal: false

# module definition
module Accounting; end

# Provides the routine to export the accounting data to an external accounting software
class Accounting::AccountingExportService
  include ActionView::Helpers::NumberHelper

  attr_reader :encoding, :format, :separator, :journal_code, :date_format, :columns, :decimal_separator, :label_max_length,
              :export_zeros

  def initialize(columns, encoding: 'UTF-8', format: 'CSV', separator: ';')
    @encoding = encoding
    @format = format
    @separator = separator
    @decimal_separator = ','
    @date_format = '%d/%m/%Y'
    @label_max_length = 50
    @export_zeros = false
    @journal_code = Setting.get('accounting_journal_code') || ''
    @columns = columns
  end

  def set_options(decimal_separator: ',', date_format: '%d/%m/%Y', label_max_length: 50, export_zeros: false)
    @decimal_separator = decimal_separator
    @date_format = date_format
    @label_max_length = label_max_length
    @export_zeros = export_zeros
  end

  def export(start_date, end_date, file)
    # build CSV content
    content = header_row
    invoices = Invoice.where('created_at >= ? AND created_at <= ?', start_date, end_date).order('created_at ASC')
    invoices = invoices.where('total > 0') unless export_zeros
    invoices.each do |i|
      Rails.logger.debug { "processing invoice #{i.id}..." } unless Rails.env.test?
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
    rows = client_rows(invoice) + items_rows(invoice)

    vat = vat_row(invoice)
    rows += "#{vat}\n" unless vat.nil?

    rows
  end

  # Generate the "subscription" and "reservation" rows associated with the provided invoice
  def items_rows(invoice)
    rows = ''
    {
      subscription: 'Subscription', reservation: 'Reservation', wallet: 'WalletTransaction',
      pack: 'StatisticProfilePrepaidPack', product: 'OrderItem', error: 'Error'
    }.each do |type, object_type|
      items = invoice.invoice_items.filter { |ii| ii.object_type == object_type }
      items.each do |item|
        rows << "#{row(
          invoice,
          account(invoice, type),
          account(invoice, type, type: :label),
          item.net_amount / 100.00,
          line_label: label(invoice)
        )}\n"
      end
    end
    rows
  end

  # Generate the "client" rows, which contains the debit to the client account, all taxes included
  def client_rows(invoice)
    rows = ''
    invoice.payment_means.each do |details|
      rows << row(
        invoice,
        account(invoice, :client, means: details[:means]),
        account(invoice, :client, means: details[:means], type: :label),
        details[:amount] / 100.00,
        line_label: label(invoice),
        debit_method: :debit_client,
        credit_method: :credit_client
      )
      rows << "\n"
    end
    rows
  end

  # Generate the "VAT" row, which contains the credit to the VAT account, with VAT amount only
  def vat_row(invoice)
    total = invoice.invoice_items.map(&:net_amount).sum
    # we do not render the VAT row if it was disabled for this invoice
    return nil if total == invoice.total

    row(
      invoice,
      account(invoice, :vat),
      account(invoice, :vat, type: :label),
      invoice.invoice_items.map(&:vat).map(&:to_i).reduce(:+) / 100.00,
      line_label: label(invoice)
    )
  end

  # Generate a row of the export, filling the configured columns with the provided values
  def row(invoice, account_code, account_label, amount, line_label: '', debit_method: :debit, credit_method: :credit)
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code.to_s
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account_code
      when 'account_label'
        row << account_label
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << line_label
      when 'debit_origin', 'debit_euro'
        row << method(debit_method).call(invoice, amount)
      when 'credit_origin', 'credit_euro'
        row << method(credit_method).call(invoice, amount)
      when 'lettering'
        row << ''
      else
        Rails.logger.debug { "Unsupported column: #{column}" }
      end
      row << separator
    end
    row
  end

  # Get the account code (or label) for the given invoice and the specified line type (client, vat, subscription or reservation)
  def account(invoice, account, type: :code, means: :other)
    case account
    when :client
      Setting.get("accounting_#{means}_client_#{type}")
    when :reservation
      Setting.get("accounting_#{invoice.main_item.object.reservable_type}_#{type}") if invoice.main_item.object_type == 'Reservation'
    else
      Setting.get("accounting_#{account}_#{type}")
    end || ''
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
    if invoice.main_item.object_type == 'Reservation'
      items.push I18n.t("accounting_export.#{invoice.main_item.object.reservable_type}_reservation")
    end
    items.push I18n.t('accounting_export.wallet') if invoice.main_item.object_type == 'WalletTransaction'
    items.push I18n.t('accounting_export.shop_order') if invoice.main_item.object_type == 'OrderItem'

    summary = items.join(' + ')
    res = "#{reference}, #{summary}"
    "#{name.truncate(label_max_length - res.length)}, #{res}"
  end
end
