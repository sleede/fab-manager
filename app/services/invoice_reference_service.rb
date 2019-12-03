# frozen_string_literal: true

# Provides methods to generate invoice references
class InvoiceReferenceService
  class << self
    def generate_reference(invoice, date: DateTime.current, avoir: false)
      pattern = Setting.find_by(name: 'invoice_reference').value

      reference = replace_invoice_number_pattern(pattern, invoice)
      reference = replace_date_pattern(reference, date)

      if avoir
        # information about refund/avoir (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, '\1')

        # remove information about online selling (X[text])
        reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
      else
        # information about online selling (X[text])
        if invoice.paid_with_stripe?
          reference.gsub!(/X\[([^\]]+)\]/, '\1')
        else
          reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        end

        # remove information about refunds (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)
      end

      reference
    end

    def generate_order_number(invoice)
      pattern = Setting.find_by(name: 'invoice_order-nb').value

      # global invoice number (nn..nn)
      reference = pattern.gsub(/n+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices(invoice, 'global'), match.to_s.length)
      end

      reference = replace_invoice_number_pattern(reference, invoice)
      replace_date_pattern(reference, invoice.created_at)
    end

    private

    ##
    # Output the given integer with leading zeros. If the given value is longer than the given
    # length, it will be truncated.
    # @param value {Integer} the integer to pad
    # @param length {Integer} the length of the resulting string.
    ##
    def pad_and_truncate(value, length)
      value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m, '\1')
    end

    ##
    # Returns the number of current invoices in the given range around the current date.
    # If range is invalid or not specified, the total number of invoices is returned.
    # @param invoice {Invoice}
    # @param range {String} 'day', 'month', 'year'
    # @return {Integer}
    ##
    def number_of_invoices(invoice, range)
      case range.to_s
      when 'day'
        start = DateTime.current.beginning_of_day
        ending = DateTime.current.end_of_day
      when 'month'
        start = DateTime.current.beginning_of_month
        ending = DateTime.current.end_of_month
      when 'year'
        start = DateTime.current.beginning_of_year
        ending = DateTime.current.end_of_year
      else
        return invoice.id
      end
      return Invoice.count unless defined? start && defined? ending

      Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start, end_date: ending).length
    end

    ##
    # Replace the date elements in the provided pattern with the date values, from the provided date
    # @param reference {string}
    # @param date {DateTime}
    ##
    def replace_date_pattern(reference, date)
      copy = reference.dup

      # full year (YYYY)
      copy.gsub!(/YYYY(?![^\[]*\])/, date.strftime('%Y'))
      # year without century (YY)
      copy.gsub!(/YY(?![^\[]*\])/, date.strftime('%y'))

      # abbreviated month name (MMM)
      copy.gsub!(/MMM(?![^\[]*\])/, date.strftime('%^b'))
      # month of the year, zero-padded (MM)
      copy.gsub!(/MM(?![^\[]*\])/, date.strftime('%m'))
      # month of the year, non zero-padded (M)
      copy.gsub!(/M(?![^\[]*\])/, date.strftime('%-m'))

      # day of the month, zero-padded (DD)
      copy.gsub!(/DD(?![^\[]*\])/, date.strftime('%d'))
      # day of the month, non zero-padded (DD)
      copy.gsub!(/DD(?![^\[]*\])/, date.strftime('%-d'))

      copy
    end

    ##
    # Replace the invoice number elements in the provided pattern with counts from the database
    # @param reference {string}
    # @param invoice {Invoice}
    ##
    def replace_invoice_number_pattern(reference, invoice)
      copy = reference.dup

      # invoice number per year (yy..yy)
      copy.gsub!(/y+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices(invoice, 'year'), match.to_s.length)
      end
      # invoice number per month (mm..mm)
      copy.gsub!(/m+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices(invoice, 'month'), match.to_s.length)
      end
      # invoice number per day (dd..dd)
      copy.gsub!(/d+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices(invoice, 'day'), match.to_s.length)
      end

      copy
    end
  end
end
