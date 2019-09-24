# frozen_string_literal: true

# Avoir is a special type of Invoice, which it inherits. It is used to
# refund an user, based on a previous invoice, or to credit an user's wallet.
class Avoir < Invoice
  belongs_to :invoice

  validates :payment_method, inclusion: { in: %w[stripe cheque transfer none cash wallet] }

  attr_accessor :invoice_items_ids

  def generate_reference
    self.reference = InvoiceReferenceService.generate_reference(self, date: created_at, avoir: true)
  end

  def expire_subscription
    user.subscription.expire(Time.now)
  end
end
