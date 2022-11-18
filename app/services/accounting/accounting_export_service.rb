# frozen_string_literal: false

# module definition
module Accounting; end

# Provides the routine to export the accounting data to an external accounting software
class Accounting::AccountingExportService
  include ActionView::Helpers::NumberHelper

  attr_reader :encoding, :format, :separator, :date_format, :columns, :decimal_separator, :label_max_length, :export_zeros

  def initialize(columns, encoding: 'UTF-8', format: 'CSV', separator: ';')
    @encoding = encoding
    @format = format
    @separator = separator
    @decimal_separator = ','
    @date_format = '%d/%m/%Y'
    @label_max_length = 50
    @export_zeros = false
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
    lines = AccountingLine.where('date >= ? AND date <= ?', start_date, end_date)
                          .order('date ASC')
    lines = lines.joins(:invoice).where('invoices.total > 0') unless export_zeros
    lines.each do |l|
      Rails.logger.debug { "processing invoice #{l.invoice_id}..." } unless Rails.env.test?
      content << "#{row(l)}\n"
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

  # Generate a row of the export, filling the configured columns with the provided values
  def row(line)
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << line.journal_code.to_s
      when 'date'
        row << line.date&.strftime(date_format)
      when 'account_code'
        row << line.account_code
      when 'account_label'
        row << line.account_label
      when 'piece'
        row << line.invoice.reference
      when 'line_label'
        row << label(line)
      when 'debit_origin', 'debit_euro'
        row << format_number(line.debit / 100.00)
      when 'credit_origin', 'credit_euro'
        row << format_number(line.credit / 100.00)
      when 'lettering'
        row << ''
      else
        Rails.logger.warn { "Unsupported column: #{column}" }
      end
      row << separator
    end
    row
  end

  # Format the given number as a string, using the configured separator
  def format_number(num)
    number_to_currency(num, unit: '', separator: decimal_separator, delimiter: '', precision: 2)
  end

  # Create a text from the given invoice, matching the accounting software rules for the labels
  def label(line)
    name = "#{line.invoicing_profile.last_name} #{line.invoicing_profile.first_name}".tr separator, ''
    summary = line.summary
    "#{name.truncate(label_max_length - summary.length)}, #{summary}"
  end
end
