# frozen_string_literal: true

# Raised when a chained footprint is detected as wrong (invoices, invoice_items, history_values)
class InvalidFootprintError < StandardError
end
