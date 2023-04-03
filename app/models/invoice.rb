# frozen_string_literal: true

# Invoice correspond to a single purchase made by an user. This purchase is linked to one or many invoice_items
class Invoice < PaymentDocument
  include NotificationAttachedObject
  require 'fileutils'
  scope :only_invoice, -> { where(type: nil) }

  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items
  belongs_to :invoicing_profile
  belongs_to :statistic_profile
  belongs_to :wallet_transaction
  belongs_to :coupon

  has_one :chained_element, as: :element, dependent: :restrict_with_exception
  has_one :avoir, class_name: 'Avoir', dependent: :destroy, inverse_of: :invoice
  has_one :payment_schedule_item, dependent: :restrict_with_error
  has_one :payment_gateway_object, as: :item, dependent: :destroy
  has_one :order, dependent: :restrict_with_error
  belongs_to :operator_profile, class_name: 'InvoicingProfile'

  has_many :accounting_lines, dependent: :destroy

  delegate :user, to: :invoicing_profile
  delegate :footprint, to: :chained_element

  before_create :add_environment
  after_create :generate_order_number, :update_reference, :chain_record
  after_update :log_changes
  after_commit :generate_and_send_invoice, on: [:create], if: :persisted?

  validates_with ClosedPeriodValidator

  def file
    dir = "invoices/#{invoicing_profile.id}"
    dir = "test/fixtures/files/invoices/#{invoicing_profile.id}" if Rails.env.test?

    # create directories if they doesn't exists (invoice & invoicing_profile_id)
    FileUtils.mkdir_p dir
    "#{dir}/#{filename}"
  end

  def filename
    prefix = Setting.find_by(name: 'invoice_prefix').value_at(created_at)
    prefix ||= if created_at < Setting.find_by(name: 'invoice_prefix').first_update
                 Setting.find_by(name: 'invoice_prefix').first_value
               else
                 Setting.get('invoice_prefix')
               end
    "#{prefix}-#{id}_#{created_at.strftime('%d%m%Y')}.pdf"
  end

  def generate_order_number
    self.order_number = order.reference and return unless order.nil? || order.reference.nil?

    if !payment_schedule_item.nil? && !payment_schedule_item.first?
      self.order_number = payment_schedule_item.payment_schedule.order_number
      return
    end

    super
  end

  # for debug & used by rake task "fablab:maintenance:regenerate_invoices"
  def regenerate_invoice_pdf
    pdf = ::Pdf::Invoice.new(self).render
    File.binwrite(file, pdf)
  end

  def build_avoir(attrs = {})
    raise CannotRefundError if refunded? == true || prevent_refund?

    avoir = Avoir.new(dup.attributes)
    avoir.type = 'Avoir'
    avoir.attributes = attrs
    avoir.reference = nil
    avoir.invoice_id = id
    avoir.avoir_date = Time.current
    avoir.total = 0
    # refunds of invoices with cash coupons: we need to ventilate coupons on paid items
    paid_items = 0
    refund_items = 0
    invoice_items.each do |ii|
      paid_items += 1 unless ii.amount.zero?
      next unless attrs[:invoice_items_ids].include? ii.id # list of items to refund (partial refunds)
      raise StandardError if ii.invoice_item # cannot refund an item that was already refunded

      refund_items += 1 unless ii.amount.zero?
      avoir_ii = avoir.invoice_items.build(ii.dup.attributes)
      avoir_ii.invoice_item_id = ii.id
      avoir.total += avoir_ii.amount
    end
    # handle coupon
    avoir.total = CouponService.apply_on_refund(avoir.total, avoir.coupon, paid_items, refund_items)
    avoir
  end

  def subscription_invoice?
    invoice_items.each do |ii|
      return true if ii.object_type == 'Subscription'
    end
    false
  end

  ##
  # Test if the current invoice has been refund, totally or partially.
  # @return {Boolean|'partial'}, true means fully refund, false means not refunded
  ##
  def refunded?
    if avoir
      invoice_items.each do |item|
        return 'partial' unless item.invoice_item
      end
      true
    else
      false
    end
  end

  ##
  # Check if the current invoice is about a training that was previously validated for the concerned user.
  # In that case refunding the invoice shouldn't be allowed.
  # Moreover, an invoice cannot be refunded if the users' account was deleted
  # @return {Boolean}
  ##
  def prevent_refund?
    return true if user.nil?

    if main_item.nil?
      Rails.logger.error "Invoice (id: #{id}) does not have a main_item and is probably in error"
      return true
    end

    if main_item.object_type == 'Reservation' && main_item.object&.reservable_type == 'Training'
      user.trainings.include?(main_item.object.reservable_id)
    else
      false
    end
  end

  def main_item
    main = invoice_items.where(main: true).first
    if main.nil?
      main = invoice_items.order(id: :asc).first
      main&.update(main: true)
    end
    main
  end

  def other_items
    invoice_items.where(main: [nil, false])
  end

  # get amount total paid
  def amount_paid
    total - (wallet_amount || 0)
  end

  # return a summary of the payment means used
  def payment_means
    res = []
    res.push(means: :wallet, amount: wallet_amount) if paid_by_wallet?
    if paid_by_card?
      res.push(means: :card, amount: amount_paid)
    else
      res.push(means: :other, amount: amount_paid)
    end
    res
  end

  def payment_details(mean)
    case mean
    when :card
      if paid_by_card?
        {
          payment_mean: mean,
          gateway_object_id: payment_gateway_object.gateway_object_id,
          gateway_object_type: payment_gateway_object.gateway_object_type
        }
      end
    when :wallet
      { payment_mean: mean, wallet_transaction_id: wallet_transaction_id } if paid_by_wallet?
    else
      { payment_mean: mean }
    end
  end

  def footprint_children
    invoice_items
  end

  def paid_by_card?
    payment_method == 'card'
  end

  def paid_by_wallet?
    wallet_transaction && wallet_amount.positive?
  end

  def render_resource
    { partial: 'api/invoices/invoice', locals: { invoice: self } }
  end

  private

  def generate_and_send_invoice
    return unless Setting.get('invoicing_module')

    unless Rails.env.test?
      Rails.logger.info "Creating an InvoiceWorker job to generate the following invoice: id(#{id}), " \
                        "main_item.object_id(#{main_item.object_id}), " \
                        "main_item.object_type(#{main_item.object_type}), user_id(#{invoicing_profile.user_id})"
    end
    InvoiceWorker.perform_async(id)
  end

  def log_changes
    return if Rails.env.test?
    return unless changed?

    Rails.logger.warn "Invoice update triggered [ id: #{id}, reference: #{reference} ]\n" \
                      "----------   changes   ----------#{changes}\n---------------------------------"
  end
end
