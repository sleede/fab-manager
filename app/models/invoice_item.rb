# frozen_string_literal: true

# A single line inside an invoice. Can be a subscription or a reservation
class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :subscription

  has_one :invoice_item # to associated invoice_items of an invoice to invoice_items of an avoir
end
