# frozen_string_literal: true

# Avoir is a special type of Invoice, which it inherits. It is used to
# refund an user, based on a previous invoice, or to credit an user's wallet.
class Avoir < Invoice
  belongs_to :invoice

  validates :avoir_mode, inclusion: { in: %w[stripe cheque transfer none cash wallet] }

  attr_accessor :invoice_items_ids

  def generate_reference
    pattern = Setting.find_by(name: 'invoice_reference').value

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
    reference.gsub!(/YYYY(?![^\[]*\])/, created_at.strftime('%Y'))
    # year without century (YY)
    reference.gsub!(/YY(?![^\[]*\])/, created_at.strftime('%y'))

    # abbreviated month name (MMM)
    reference.gsub!(/MMM(?![^\[]*\])/, created_at.strftime('%^b'))
    # month of the year, zero-padded (MM)
    reference.gsub!(/MM(?![^\[]*\])/, created_at.strftime('%m'))
    # month of the year, non zero-padded (M)
    reference.gsub!(/M(?![^\[]*\])/, created_at.strftime('%-m'))

    # day of the month, zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, created_at.strftime('%d'))
    # day of the month, non zero-padded (DD)
    reference.gsub!(/DD(?![^\[]*\])/, created_at.strftime('%-d'))

    # information about refund/avoir (R[text])
    reference.gsub!(/R\[([^\]]+)\]/, '\1')

    # remove information about online selling (X[text])
    reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)

    self.reference = reference
  end

  def expire_subscription
    user.subscription.expire(Time.now)
  end
end
