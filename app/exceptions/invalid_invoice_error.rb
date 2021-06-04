# frozen_string_literal: true

# Raised when an invalid invoice is encountered in database
class InvalidInvoiceError < StandardError
  def initialize(msg = nil)
    super(msg || 'Please run rails `fablab:fix_invoices`')
  end
end
