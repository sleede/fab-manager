# frozen_string_literal: true

# Avoir is a special type of Invoice, which it inherits. It is used to
# refund an user, based on a previous invoice, or to credit an user's wallet.
class Avoir < Invoice
  belongs_to :invoice

  after_create :notify_admins_refund_created

  # TODO, remove stripe from this list in a future release. For now, we leave it here to allow data migration to v5.0
  validates :payment_method, inclusion: { in: %w[stripe card cheque transfer none cash wallet] }

  attr_accessor :invoice_items_ids

  delegate :order_number, to: :invoice, allow_nil: true

  def expire_subscription
    user.subscription.expire
  end

  private

  def notify_admins_refund_created
    NotificationCenter.call type: 'notify_admin_refund_created',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end
end
