# frozen_string_literal: true

# Provides methods to generate Invoice, Avoir or PaymentSchedule references
class PaymentDocumentService
  class << self
    include DbHelper
    # @param document [PaymentDocument]
    # @param date [Time]
    def generate_reference(document, date: Time.current)
      pattern = Invoices::NumberService.pattern(document.created_at, 'invoice_reference')

      reference = replace_document_number_pattern(pattern, document)
      reference = replace_date_pattern(reference, date)
      replace_document_type_pattern(document, reference)
    end

    # @param document [PaymentDocument]
    def generate_order_number(document)
      pattern = Invoices::NumberService.pattern(document.created_at, 'invoice_order-nb')

      # global document number (nn..nn)
      reference = pattern.gsub(/n+(?![^\[]*\])/) do |match|
        pad_and_truncate(order_number(document, 'global'), match.to_s.length)
      end

      reference = replace_document_number_pattern(reference, document, :order_number)
      replace_date_pattern(reference, document.created_at)
    end

    # Generate a reference for the given document using the given document number
    # @param number [Integer]
    # @param document [PaymentDocument]
    def generate_numbered_reference(number, document)
      pattern = Invoices::NumberService.pattern(document.created_at, 'invoice_reference')

      reference = pattern.gsub(/n+|y+|m+|d+(?![^\[]*\])/) do |match|
        pad_and_truncate(number, match.to_s.length)
      end
      reference = replace_date_pattern(reference, document.created_at)
      replace_document_type_pattern(document, reference)
    end

    private

    # Output the given integer with leading zeros. If the given value is longer than the given
    # length, it will be truncated.
    # @param value [Integer] the integer to pad
    # @param length [Integer] the length of the resulting string.
    def pad_and_truncate(value, length)
      value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m, '\1')
    end

    # @param document [PaymentDocument]
    # @param periodicity [String] 'day' | 'month' | 'year' | 'global'
    # @return [PaymentDocument,NilClass]
    def previous_document(document, periodicity)
      previous = document.class.base_class.where('created_at < ?', db_time(document.created_at))
                         .order(created_at: :desc)
                         .limit(1)
      if %w[day month year].include?(periodicity)
        previous = previous.where('date_trunc(:periodicity, created_at) = :date',
                                  periodicity: periodicity,
                                  date: document.created_at.utc.send("beginning_of_#{periodicity}").to_date)
      end

      previous.first
    end

    # @param document [PaymentDocument]
    # @param periodicity [String] 'day' | 'month' | 'year' | 'global'
    # @return [Hash<Symbol->Footprintable,Number>]
    def previous_order(document, periodicity)
      start = periodicity == 'global' ? nil : document.created_at.send("beginning_of_#{periodicity}")
      ending = document.created_at
      orders = orders_in_range(document, start, ending)
      schedules = schedules_in_range(document, start, ending)

      invoices = Invoice.where(type: nil)
                        .where.not(id: orders.map(&:invoice_id))
                        .where.not(id: schedules.map(&:payment_schedule_items).flatten.map(&:invoice_id).filter(&:present?))
                        .where('created_at < :end_date', end_date: db_time(ending))
      invoices = invoices.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?

      last_with_number = [
        orders.where.not(reference: nil).order(created_at: :desc).limit(1).first,
        schedules.where.not(order_number: nil).order(created_at: :desc).limit(1).first,
        invoices.where.not(order_number: nil).order(created_at: :desc).limit(1).first
      ].filter(&:present?).max_by { |item| item&.created_at }
      {
        last_order: last_with_number,
        unnumbered: orders_without_number(orders, schedules, invoices, last_with_number)
      }
    end

    def orders_without_number(orders, schedules, invoices, last_item_with_number = nil)
      items_after(orders.where(reference: nil), last_item_with_number).count +
        items_after(schedules.where(order_number: nil), last_item_with_number).count +
        items_after(invoices.where(order_number: nil), last_item_with_number).count
    end

    # @param items [ActiveRecord::Relation]
    # @param previous_item [Footprintable,NilClass]
    # @return [ActiveRecord::Relation]
    def items_after(items, previous_item = nil)
      return items if previous_item.nil?

      items.where('created_at > :date', date: previous_item&.created_at)
    end

    # @param document [PaymentDocument] invoice to exclude
    # @param start [Time,NilClass]
    # @param ending [Time]
    # @return [ActiveRecord::Relation<Order>,ActiveRecord::QueryMethods::WhereChain]
    def orders_in_range(document, start, ending)
      orders = Order.where('created_at < :end_date', end_date: db_time(ending))
      orders = orders.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?
      orders = orders.where.not(id: document.order.id) if document.is_a?(Invoice) && document.order.present?
      orders
    end

    # @param document [PaymentDocument] invoice to exclude
    # @param start [Time,NilClass]
    # @param ending [Time]
    # @return [ActiveRecord::Relation<PaymentSchedule>,ActiveRecord::QueryMethods::WhereChain]
    def schedules_in_range(document, start, ending)
      schedules = PaymentSchedule.where('created_at < :end_date', end_date: db_time(ending))
      schedules = schedules.where('created_at >= :start_date', start_date: db_time(start)) unless start.nil?
      if document.is_a?(Invoice) && document.payment_schedule_item.present?
        schedules = schedules.where.not(id: document.payment_schedule_item.payment_schedule.id)
      end
      schedules
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

    # @param document [PaymentDocument]
    # @param periodicity [String] 'day' | 'month' | 'year' | 'global'
    # @return [Integer]
    def document_number(document, periodicity)
      previous = previous_document(document, periodicity)
      number = Invoices::NumberService.number(previous) if Invoices::NumberService.number_periodicity(previous) == periodicity
      number ||= 0

      number + 1
    end

    # @param document [PaymentDocument]
    # @param periodicity [String] 'day' | 'month' | 'year' | 'global'
    # @return [Integer]
    def order_number(document, periodicity)
      previous = previous_order(document, periodicity)
      if Invoices::NumberService.number_periodicity(previous[:last_order], 'invoice_order-nb') == periodicity
        number = Invoices::NumberService.number(previous[:last_order], 'invoice_order-nb')
      end
      number ||= 0

      number + previous[:unnumbered] + 1
    end

    # Replace the document number elements in the provided pattern with counts from the database
    # @param reference [String]
    # @param document [PaymentDocument]
    # @param numeration_method [Symbol] :document_number OR :order_number
    def replace_document_number_pattern(reference, document, numeration_method = :document_number)
      copy = reference.dup

      # document number per year (yy..yy)
      copy.gsub!(/y+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(numeration_method, document, 'year'), match.to_s.length)
      end
      # document number per month (mm..mm)
      copy.gsub!(/m+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(numeration_method, document, 'month'), match.to_s.length)
      end
      # document number per day (dd..dd)
      copy.gsub!(/d+(?![^\[]*\])/) do |match|
        pad_and_truncate(send(numeration_method, document, 'day'), match.to_s.length)
      end

      copy
    end

    # @param document [PaymentDocument]
    # @param pattern [String]
    # @return [String]
    def replace_document_type_pattern(document, pattern)
      copy = pattern.dup
      case document
      when Avoir
        # information about refund/avoir (R[text])
        copy.gsub!(/R\[([^\]]+)\]/, '\1')

        # remove information about online selling (X[text])
        copy.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        copy.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      when PaymentSchedule
        # information about payment schedule
        copy.gsub!(/S\[([^\]]+)\]/, '\1')
        # remove information about online selling (X[text])
        copy.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about refunds (R[text])
        copy.gsub!(/R\[([^\]]+)\]/, ''.to_s)
      when Invoice
        # information about online selling (X[text])
        if document.paid_by_card?
          copy.gsub!(/X\[([^\]]+)\]/, '\1')
        else
          copy.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        end

        # remove information about refunds (R[text])
        copy.gsub!(/R\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        copy.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      else
        # maybe an Order or anything else,
        # remove all informations
        copy.gsub!(/S\[([^\]]+)\]/, ''.to_s)
        copy.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        copy.gsub!(/R\[([^\]]+)\]/, ''.to_s)
      end

      copy
    end
  end
end
