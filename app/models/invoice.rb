class Invoice < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject
  require 'fileutils'
  scope :only_invoice, -> { where(type: nil) }
  belongs_to :invoiced, polymorphic: true

  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items
  belongs_to :user
  belongs_to :wallet_transaction
  belongs_to :coupon

  has_one :avoir, class_name: 'Invoice', foreign_key: :invoice_id, dependent: :destroy

  after_create :update_reference
  after_commit :generate_and_send_invoice, on: [:create], :if => :persisted?

  def file
    dir = "invoices/#{user.id}"

    # create directories if they doesn't exists (invoice & user_id)
    FileUtils::mkdir_p dir
    "#{dir}/#{self.filename}"
  end

  def filename
    "#{ENV['INVOICE_PREFIX']}-#{self.id}_#{self.created_at.strftime('%d%m%Y')}.pdf"
  end


  def generate_reference
    pattern = Setting.find_by({name: 'invoice_reference'}).value

    # invoice number per day (dd..dd)
    reference = pattern.gsub(/d+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('day'), match.to_s.length)
    end
    # invoice number per month (mm..mm)
    reference.gsub!(/m+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('month'), match.to_s.length)
    end
    # invoice number per year (yy..yy)
    reference.gsub!(/y+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('year'), match.to_s.length)
    end

    # full year (YYYY)
    reference.gsub!(/YYYY(?![^\[]*\])/, Time.now.strftime('%Y'))
    # year without century (YY)
    reference.gsub!(/YY(?![^\[]*\])/, Time.now.strftime('%y'))

    # abreviated month name (MMM)
    reference.gsub!(/MMM(?![^\[]*\])/, Time.now.strftime('%^b'))
    # month of the year, zero-padded (MM)
    reference.gsub!(/MM(?![^\[]*\])/, Time.now.strftime('%m'))
    # month of the year, non zero-padded (M)
    reference.gsub!(/M(?![^\[]*\])/, Time.now.strftime('%-m'))

    # day of the month, zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, Time.now.strftime('%d'))
    # day of the month, non zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, Time.now.strftime('%-d'))

    # information about online selling (X[text])
    if self.stp_invoice_id
      reference.gsub!(/X\[([^\]]+)\]/, '\1')
    else
      reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
    end

    # information about wallet (W[text])
    #reference.gsub!(/W\[([^\]]+)\]/, ''.to_s)

    # remove information about refunds (R[text])
    reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)

    self.reference = reference
  end

  def update_reference
    generate_reference
    save
  end

  def order_number
    pattern = Setting.find_by({name: 'invoice_order-nb'}).value

    # global invoice number (nn..nn)
    reference = pattern.gsub(/n+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('global'), match.to_s.length)
    end
    # invoice number per year (yy..yy)
    reference.gsub!(/y+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('year'), match.to_s.length)
    end
    # invoice number per month (mm..mm)
    reference.gsub!(/m+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('month'), match.to_s.length)
    end
    # invoice number per day (dd..dd)
    reference.gsub!(/d+(?![^\[]*\])/) do |match|
      pad_and_truncate(number_of_invoices('day'), match.to_s.length)
    end

    # full year (YYYY)
    reference.gsub!(/YYYY(?![^\[]*\])/, self.created_at.strftime('%Y'))
    # year without century (YY)
    reference.gsub!(/YY(?![^\[]*\])/, self.created_at.strftime('%y'))

    # abreviated month name (MMM)
    reference.gsub!(/MMM(?![^\[]*\])/, self.created_at.strftime('%^b'))
    # month of the year, zero-padded (MM)
    reference.gsub!(/MM(?![^\[]*\])/, self.created_at.strftime('%m'))
    # month of the year, non zero-padded (M)
    reference.gsub!(/M(?![^\[]*\])/, self.created_at.strftime('%-m'))

    # day of the month, zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, self.created_at.strftime('%d'))
    # day of the month, non zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, self.created_at.strftime('%-d'))

    reference
  end

  # for debug & used by rake task "fablab:regenerate_invoices"
  def regenerate_invoice_pdf
    pdf = ::PDF::Invoice.new(self).render
    File.binwrite(file, pdf)
  end

  def build_avoir(attrs = {})
    raise Exception if has_avoir === true or prevent_refund?
    avoir = Avoir.new(self.dup.attributes)
    avoir.type = 'Avoir'
    avoir.attributes = attrs
    avoir.reference = nil
    avoir.invoice_id = id
    # override created_at to compute CA in stats
    avoir.created_at = avoir.avoir_date
    avoir.total = 0
    # refunds of invoices with cash coupons: we need to ventilate coupons on paid items
    paid_items = 0
    refund_items = 0
    invoice_items.each do |ii|
      paid_items += 1 unless ii.amount == 0
      if attrs[:invoice_items_ids].include? ii.id  # list of items to refund (partial refunds)
        raise Exception if ii.invoice_item  # cannot refund an item that was already refunded
        refund_items += 1 unless ii.amount == 0
        avoir_ii = avoir.invoice_items.build(ii.dup.attributes)
        avoir_ii.created_at = avoir.avoir_date
        avoir_ii.invoice_item_id = ii.id
        avoir.total += avoir_ii.amount
      end
    end
    # handle coupon
    unless avoir.coupon_id.nil?
      discount = avoir.total
      if avoir.coupon.type == 'percent_off'
        discount = avoir.total * avoir.coupon.percent_off / 100.0
      elsif avoir.coupon.type == 'amount_off'
        discount = (avoir.coupon.amount_off / paid_items) * refund_items
      else
        raise InvalidCouponError
      end
      avoir.total -= discount
    end
    avoir
  end

  def is_subscription_invoice?
    invoice_items.each do |ii|
      return true if ii.subscription and !ii.subscription.is_expired?
    end
    false
  end

  ##
  # Test if the current invoice has been refund, totally or partially.
  # @return {Boolean|'partial'}, true means fully refund, false means not refunded
  ##
  def has_avoir
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
  # @return {Boolean}
  ##
  def prevent_refund?
    if invoiced_type == 'Reservation' and invoiced.reservable_type == 'Training'
      user.trainings.include?(invoiced.reservable_id)
    else
      false
    end
  end

  private
  def generate_and_send_invoice
    puts "Creating an InvoiceWorker job to generate the following invoice: id(#{id}), invoiced_id(#{invoiced_id}), invoiced_type(#{invoiced_type}), user_id(#{user_id})"
    InvoiceWorker.perform_async(id)
  end

  ##
  # Output the given integer with leading zeros. If the given value is longer than the given
  # length, it will be truncated.
  # @param value {Integer} the integer to pad
  # @param length {Integer} the length of the resulting string.
  ##
  def pad_and_truncate (value, length)
    value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m,'\1')
  end

  ##
  # Returns the number of current invoices in the given range around the current date.
  # If range is invalid or not specified, the total number of invoices is returned.
  # @param range {String} 'day', 'month', 'year'
  # @return {Integer}
  ##
  def number_of_invoices(range)
    case range.to_s
      when 'day'
        start = DateTime.current.beginning_of_day
        ending = DateTime.current.end_of_day
      when 'month'
        start = DateTime.current.beginning_of_month
        ending = DateTime.current.end_of_month
      when 'year'
        start = DateTime.current.beginning_of_year
        ending = DateTime.current.end_of_year
      else
        return self.id
    end
    if defined? start and defined? ending
      Invoice.where('created_at >= :start_date AND created_at < :end_date', {start_date: start, end_date: ending}).length
    end
  end

end
