# frozen_string_literal: true

# Avoir is a special type of Invoice, which it inherits. It is used to
# refund an user, based on a previous invoice, or to credit an user's wallet.
class Avoir < Invoice
  belongs_to :invoice

  after_create :notify_admins_refund_created

  validates :payment_method, inclusion: { in: %w[stripe cheque transfer none cash wallet] }

  attr_accessor :invoice_items_ids

  def generate_reference
    super(created_at)
  end

  def expire_subscription
    user.subscription.expire(DateTime.current)
  end

  private

  def notify_admins_refund_created
    NotificationCenter.call type: 'notify_admin_refund_created',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end
end
