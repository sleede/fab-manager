# frozen_string_literal: true

# Provides methods to generate Invoice, Avoir or PaymentSchedule references
class PaymentDocumentService
  class << self
    include DbHelper
    # @param document [PaymentDocument]
    # @param date [Time]
    def generate_reference(document, date: Time.current)
      pattern = Setting.get('invoice_reference').to_s

      reference = replace_document_number_pattern(pattern, document, document.created_at)
      reference = replace_date_pattern(reference, date)

      case document
      when Avoir
        # information about refund/avoir (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, '\1')

        # remove information about online selling (X[text])
        reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        reference.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      when PaymentSchedule
        # information about payment schedule
        reference.gsub!(/S\[([^\]]+)\]/, '\1')
        # remove information about online selling (X[text])
        reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about refunds (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)
      when Invoice
        # information about online selling (X[text])
        if document.paid_by_card?
          reference.gsub!(/X\[([^\]]+)\]/, '\1')
        else
          reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        end

        # remove information about refunds (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        reference.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      else
        raise TypeError
      end

      reference
    end

    # @param document [PaymentDocument]
    def generate_order_number(document)
      pattern = Setting.get('invoice_order-nb')

      # global document number (nn..nn)
      reference = pattern.gsub(/n+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_order('global', document, document.created_at), match.to_s.length)
      end

      reference = replace_document_number_pattern(reference, document, document.created_at, :number_of_order)
      replace_date_pattern(reference, document.created_at)
    end

    private

    # Output the given integer with leading zeros. If the given value is longer than the given
    # length, it will be truncated.
    # @param value [Integer] the integer to pad
    # @param length [Integer] the length of the resulting string.
    def pad_and_truncate(value, length)
      value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m, '\1')
    end

    # Returns the number of current invoices in the given range around the current date.
    # If range is invalid or not specified, the total number of invoices is returned.
    # @param range [String] 'day', 'month', 'year'
    # @param document [PaymentDocument]
    # @param date [Time] the ending date
    # @return [Integer]
    def number_of_documents(range, document, date = Time.current)
      start = case range.to_s
              when 'day'
                date.beginning_of_day
              when 'month'
                date.beginning_of_month
              when 'year'
                date.beginning_of_year
              else
                nil
              end
      ending = date

      documents = document.class.base_class
                          .where('created_at <= :end_date', end_date: db_time(ending))

      documents = documents.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?

      documents.count
    end

    def number_of_order(range, _document, date = Time.current)
      start = case range.to_s
              when 'day'
                date.beginning_of_day
              when 'month'
                date.beginning_of_month
              when 'year'
                date.beginning_of_year
              else
                nil
              end
      ending = date
      orders = Order.where('created_at <= :end_date', end_date: db_time(ending))
      orders = orders.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?

      schedules = PaymentSchedule.where('created_at <= :end_date', end_date: db_time(ending))
      schedules = schedules.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?

      invoices = Invoice.where(type: nil)
                        .where.not(id: orders.map(&:invoice_id))
                        .where.not(id: schedules.map(&:payment_schedule_items).flatten.map(&:invoice_id).filter(&:present?))
                        .where('created_at <= :end_date', end_date: db_time(ending))
      invoices = invoices.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?

      orders.count + schedules.count + invoices.count
    end

    # Replace the date elements in the provided pattern with the date values, from the provided date
    # @param reference [String]
    # @param date [Time]
    def replace_date_pattern(reference, date)
      copy = reference.dup

      # full year (YYYY)
      copy.gsub!(/(?![^\[]*\])YYYY(?![^\[]*\])/, date.strftime('%Y'))
      # year without century (YY)
      copy.gsub!(/(?![^\[]*\])YY(?![^\[]*\])/, date.strftime('%y'))

      # abbreviated month name (MMM)
      # we cannot replace by the month name directly because it may contrains an M or a D
      # so we replace it by a special indicator and, at the end, we will replace it by the abbreviated month name
      copy.gsub!(/(?![^\[]*\])MMM(?![^\[]*\])/, '}~{')
      # month of the year, zero-padded (MM)
      copy.gsub!(/(?![^\[]*\])MM(?![^\[]*\])/, date.strftime('%m'))
      # month of the year, non zero-padded (M)
      copy.gsub!(/(?![^\[]*\])M(?![^\[]*\])/, date.strftime('%-m'))

      # day of the month, zero-padded (DD)
      copy.gsub!(/(?![^\[]*\])DD(?![^\[]*\])/, date.strftime('%d'))
      # day of the month, non zero-padded (D)
      copy.gsub!(/(?![^\[]*\])D(?![^\[]*\])/, date.strftime('%-d'))

      # abbreviated month name (MMM) (2)
      copy.gsub!(/(?![^\[]*\])}~\{(?![^\[]*\])/, date.strftime('%^b'))

      copy
    end

    # Replace the document number elements in the provided pattern with counts from the database
    # @param reference [String]
    # @param document [PaymentDocument]
    # @param date [Time]
    # @param count_method [Symbol] :number_of_documents OR :number_of_order
    def replace_document_number_pattern(reference, document, date, count_method = :number_of_documents)
      copy = reference.dup

      # document number per year (yy..yy)
      copy.gsub!(/y+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(count_method, 'year', document, date), match.to_s.length)
      end
      # document number per month (mm..mm)
      copy.gsub!(/m+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(count_method, 'month', document, date), match.to_s.length)
      end
      # document number per day (dd..dd)
      copy.gsub!(/d+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(count_method, 'day', document, date), match.to_s.length)
      end

      copy
    end
  end
end
