# frozen_string_literal: true

# Represents a due date and the associated amount for a PaymentSchedule
class PaymentScheduleItem < Footprintable
  belongs_to :payment_schedule
  belongs_to :invoice
  has_one :payment_gateway_object

  after_create :chain_record

  def first?
    payment_schedule.ordered_items.first == self
  end

  def payment_intent
    return unless payment_gateway_object
    # FIXME
    key = Setting.get('stripe_secret_key')
    stp_invoice = Stripe::Invoice.retrieve(stp_invoice_id, api_key: key)
    Stripe::PaymentIntent.retrieve(stp_invoice.payment_intent, api_key: key)
  end

  def self.columns_out_of_footprint
    %w[invoice_id state payment_method client_secret]
  end
end
