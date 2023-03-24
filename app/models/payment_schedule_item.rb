# frozen_string_literal: true

# Represents a due date and the associated amount for a PaymentSchedule
class PaymentScheduleItem < Footprintable
  belongs_to :payment_schedule
  belongs_to :invoice
  has_one :payment_gateway_object, as: :item, dependent: :destroy
  has_one :chained_element, as: :element, dependent: :restrict_with_exception

  after_create :chain_record

  delegate :footprint, to: :chained_element

  def first?
    payment_schedule.ordered_items.first == self
  end

  def payment_intent
    return unless payment_gateway_object
    return unless payment_gateway_object.gateway_object.gateway == 'Stripe'

    stp_invoice = payment_gateway_object.gateway_object.retrieve
    Stripe::PaymentIntent.retrieve(stp_invoice.payment_intent, api_key: Setting.get('stripe_secret_key'))
  end

  def self.columns_out_of_footprint
    %w[invoice_id state payment_method client_secret]
  end
end
