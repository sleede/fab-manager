# frozen_string_literal: true

# PaymentSchedule is a way for members to pay something (especially a Subscription) with multiple payment,
# staged on a long period rather than with a single payment
class PaymentSchedule < ApplicationRecord
  belongs_to :scheduled, polymorphic: true
  belongs_to :wallet_transaction
  belongs_to :coupon
  belongs_to :invoicing_profile
  belongs_to :operator_profile, foreign_key: :operator_profile_id, class_name: 'InvoicingProfile'

  belongs_to :subscription, foreign_type: 'Subscription', foreign_key: 'scheduled_id'
  belongs_to :reservation, foreign_type: 'Reservation', foreign_key: 'scheduled_id'

  has_many :payment_schedule_items

  ##
  # This is useful to check the first item because its amount may be different from the others
  ##
  def ordered_items
    payment_schedule_items.order(due_date: :asc)
  end
end
