# frozen_string_literal: true

# module definition
module Invoices; end

# The invoice number is based on the previous invoice
class Invoices::NumberService
  class << self
    # Get the order number or reference number for the given invoice (not the whole identifier).
    # The date part, online payment part, etc. will be excluded and only the number part will be returned.
    # @param document [PaymentDocument,NilClass]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [Integer,NilClass]
    def number(document, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)
      return nil if document.nil?

      saved_number = setting == 'invoice_reference' ? document.reference : document.order_number
      return nil if saved_number.nil?

      indices = number_indices(document, setting)
      saved_number[indices[0]..indices[1]]&.to_i
    end

    # Search for any document matching the provided period and number
    # @param number [Integer] the number to search
    # @param date [Time] the date to search around, when using periodicity != 'global'
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @param klass [Class] Invoice | Order | PaymentSchedule
    # @return [PaymentDocument,NilClass]
    def find_by_number(number, date: Time.current, setting: 'invoice_reference', klass: Invoice)
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)
      return nil if number.nil?

      pattern = pattern(date, setting)
      pattern = pattern.gsub(/([SXR]\[[^\]]+\])+/, '%')
      case pattern
      when /n+/
        pattern = pattern.gsub(/[YMD]+/) { |match| '_' * match.to_s.length }
      when /y+/
        pattern = pattern.gsub(/[MD]+/) { |match| '_' * match.to_s.length }
      when /m+/
        pattern = pattern.gsub(/D+/) { |match| '_' * match.to_s.length }
      end
      pattern = PaymentDocumentService.send(:replace_date_pattern, pattern, date)

      pattern = pattern.gsub(/n+|y+|m+|d+/) do |match|
        pad_and_truncate(number, match.to_s.length)
      end

      field = setting == 'invoice_reference' ? 'reference' : 'order_number'
      field = 'reference' if klass == Order
      klass.where("#{field} LIKE '#{pattern}'").first
    end

    # @param document [PaymentDocument,NilClass]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [String,NilClass] 'global' | 'year' | 'month' | 'day'
    def number_periodicity(document, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)
      return nil if document.nil?

      pattern = pattern(document.created_at, setting)
      pattern = PaymentDocumentService.send(:replace_document_type_pattern, document, pattern)

      return 'global' if pattern.match?(/n+/)
      return 'year' if pattern.match?(/y+/)
      return 'month' if pattern.match?(/m+/)
      return 'day' if pattern.match?(/d+/)

      nil
    end

    # Get the pattern applicable to generate the given number at the given date.
    # @param date [Time]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [String]
    def pattern(date, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)

      value = Setting.find_by(name: setting).value_at(date)
      value || if date < Setting.find_by(name: setting).first_update
                 Setting.find_by(name: setting).first_value
               else
                 Setting.get(setting)
               end
    end

    private

    # Output the given integer with leading zeros. If the given value is longer than the given
    # length, it will be truncated.
    # @param value [Integer] the integer to pad
    # @param length [Integer] the length of the resulting string.
    def pad_and_truncate(value, length)
      value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m, '\1')
    end

    # Return the indices of the number in the document's reference
    # @param document [PaymentDocument,NilClass]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [Array<Integer>]
    def number_indices(document, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)
      return nil if document.nil?

      pattern = pattern(document.created_at, setting)
      pattern = PaymentDocumentService.send(:replace_document_type_pattern, document, pattern)
      start_idx = pattern.index(/n+|y+|m+|d+/)
      end_idx = pattern.rindex(/n+|y+|m+|d+/)
      [start_idx, end_idx]
    end
  end
end
