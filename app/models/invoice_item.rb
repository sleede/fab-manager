# frozen_string_literal: true

# A single line inside an invoice. Can be a subscription or a reservation
class InvoiceItem < Footprintable
  belongs_to :invoice

  has_one :invoice_item, dependent: :destroy # associates invoice_items of an invoice to invoice_items of an Avoir
  has_one :payment_gateway_object, as: :item, dependent: :destroy

  has_one :chained_element, as: :element, dependent: :restrict_with_exception
  belongs_to :object, polymorphic: true

  after_create :chain_record
  after_update :log_changes

  delegate :footprint, to: :chained_element

  def amount_after_coupon
    # deduct coupon discount
    coupon_service = CouponService.new
    total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
    coupon_service.ventilate(total_without_coupon, amount, invoice.coupon)
  end

  # return the item amount, coupon discount deducted, if any, and VAT excluded, if applicable
  def net_amount
    # deduct VAT
    vat_service = VatHistoryService.new
    vat_rate = vat_service.invoice_item_vat(self)
    Rational(amount_after_coupon / ((vat_rate / 100.00) + 1)).round.to_f
  end

  # return the VAT amount for this item
  def vat
    amount_after_coupon - net_amount
  end

  # return invoice item type (Machine/Training/Space/Event/Subscription/OrderItem) used to determine the VAT rate
  def invoice_item_type
    if object_type == Reservation.name
      object.try(:reservable_type) || ''
    elsif [Subscription.name, OfferDay.name].include? object_type
      Subscription.name
    elsif object_type == StatisticProfilePrepaidPack.name
      object.prepaid_pack.priceable_type
    elsif object_type == OrderItem.name
      Product.name
    else
      ''
    end
  end

  private

  def log_changes
    return if Rails.env.test?
    return unless changed?

    Rails.logger.warn "InvoiceItem update triggered [ id: #{id}, invoice reference: #{invoice.reference} ]\n" \
                      "----------   changes   ----------\n#{changes}\n---------------------------------"
  end
end
