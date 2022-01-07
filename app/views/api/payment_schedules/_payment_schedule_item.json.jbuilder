# frozen_string_literal: true

json.extract! item, :id, :due_date, :state, :invoice_id, :payment_method
json.amount item.amount / 100.00
