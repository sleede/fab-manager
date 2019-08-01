# frozen_string_literal: false

# Provides the routine to export the accounting data to an external accounting software
class AccountingExportService
  attr_reader :encoding, :format, :separator, :journal_code, :date_format, :columns, :vat_service

  def initialize(columns, encoding = 'UTF-8', format = 'CSV', separator = ';', date_format = '%d/%m/%Y')
    @encoding = encoding
    @format = format
    @separator = separator
    @journal_code = Setting.find_by(name: 'accounting_journal_code')&.value || ''
    @date_format = date_format
    @columns = columns
    @vat_service = VatHistoryService.new
  end

  def export(start_date, end_date, file)
    # build CVS content
    content = header_row
    invoices = Invoice.where('created_at >= ? AND created_at <= ?', start_date, end_date).order('created_at ASC')
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
    "#{client_row(invoice)}\n" \
      "#{items_rows(invoice)}" \
      "#{vat_row(invoice)}\n"
  end

  # Generate the "subscription" and "reservation" rows associated with the provided invoice
  def items_rows(invoice)
    rows = invoice.subscription_invoice? ? "#{subscription_row(invoice)}\n" : ''
    if invoice.invoiced_type == 'Reservation'
      invoice.invoice_items.each do |item|
        rows << "#{reservation_row(invoice, item)}\n"
      end
    end
    rows
  end

  # Generate the "client" row, which contains the debit to the client account, all taxes included
  def client_row(invoice)
    total = invoice.total / 100.0
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
        row << invoice.invoicing_profile.full_name
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
    wo_taxes = (item.amount / (vat_service.invoice_vat(invoice) / 100 + 1)) / 100.0
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
        row << item.description
      when 'debit_origin'
        row << debit(invoice, wo_taxes)
      when 'credit_origin'
        row << credit(invoice, wo_taxes)
      when 'debit_euro'
        row << debit(invoice, wo_taxes)
      when 'credit_euro'
        row << credit(invoice, wo_taxes)
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
    wo_taxes = (subscription_item.amount / (vat_service.invoice_vat(invoice) / 100 + 1)) / 100.0
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
        row << subscription_item.description
      when 'debit_origin'
        row << debit(invoice, wo_taxes)
      when 'credit_origin'
        row << credit(invoice, wo_taxes)
      when 'debit_euro'
        row << debit(invoice, wo_taxes)
      when 'credit_euro'
        row << credit(invoice, wo_taxes)
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
    vat = (invoice.total - (invoice.total / (vat_service.invoice_vat(invoice) / 100 + 1))) / 100.0
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
        row << I18n.t('accounting_export.VAT')
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
            Setting.find_by(name: "accounting_client_#{type}")&.value
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
          else
            puts "Unsupported account #{account}"
          end
    res || ''
  end

  # Fill the value of the "debit" column: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def debit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? amount.to_s : '0'
  end

  # Fill the value of the "credit" column: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def credit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? '0' : amount.to_s
  end

  # Fill the value of the "debit" column for the client row: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def debit_client(invoice, amount)
    credit(invoice, amount)
  end

  # Fill the value of the "credit" column, for the client row: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def credit_client(invoice, amount)
    debit(invoice, amount)
  end
end
