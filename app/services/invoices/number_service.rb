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

      pattern = pattern(document, setting)
      pattern = PaymentDocumentService.send(:replace_document_type_pattern, document, pattern)
      start_idx = pattern.index(/n+|y+|m+|d+/)
      end_idx = pattern.rindex(/n+|y+|m+|d+/)

      saved_number[start_idx..end_idx]&.to_i
    end

    # @param document [PaymentDocument,NilClass]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [String,NilClass] 'global' | 'year' | 'month' | 'day'
    def number_periodicity(document, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)
      return nil if document.nil?

      pattern = pattern(document, setting)
      pattern = PaymentDocumentService.send(:replace_document_type_pattern, document, pattern)

      return 'global' if pattern.match?(/n+/)
      return 'year' if pattern.match?(/y+/)
      return 'month' if pattern.match?(/m+/)
      return 'day' if pattern.match?(/d+/)

      nil
    end

    # Get the pattern applicable to generate the number of the given invoice.
    # @param document [PaymentDocument]
    # @param setting [String] 'invoice_reference' | 'invoice_order-nb'
    # @return [String]
    def pattern(document, setting = 'invoice_reference')
      raise TypeError, "invalid setting #{setting}" unless %w[invoice_order-nb invoice_reference].include?(setting)

      value = Setting.find_by(name: setting).value_at(document.created_at)
      value || if document.created_at < Setting.find_by(name: setting).first_update
                 Setting.find_by(name: setting).first_value
               else
                 Setting.get(setting)
               end
    end
  end
end
