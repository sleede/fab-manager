# frozen_string_literal: true

require 'checksum'

# A single line inside an invoice. Can be a subscription or a reservation
class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :subscription

  has_one :invoice_item # to associated invoice_items of an invoice to invoice_items of an avoir

  after_create :chain_record
  after_update :log_changes

  def chain_record
    self.footprint = compute_footprint
    save!
  end

  def check_footprint
    footprint == compute_footprint
  end

  def amount_after_coupon
    # deduct coupon discount
    coupon_service = CouponService.new
    coupon_service.ventilate(invoice.total, amount, invoice.coupon)
  end

  # return the item amount, coupon discount deducted, if any, and VAT excluded, if applicable
  def net_amount
    # deduct VAT
    vat_service = VatHistoryService.new
    vat_rate = vat_service.invoice_vat(invoice)
    Rational(amount_after_coupon / (vat_rate / 100.00 + 1)).round.to_f
  end

  # return the VAT amount for this item
  def vat
    amount_after_coupon - net_amount
  end

  private

  def compute_footprint
    FootprintService.compute_footprint(InvoiceItem, self)
  end

  def log_changes
    return if Rails.env.test?
    return unless changed?

    puts "WARNING: InvoiceItem update triggered [ id: #{id}, invoice reference: #{invoice.reference} ]"
    puts '----------   changes   ----------'
    puts changes
    puts '---------------------------------'
  end
end
