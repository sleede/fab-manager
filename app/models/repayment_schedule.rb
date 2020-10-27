# frozen_string_literal: true

# RepaymentSchedule is a way for members to pay something (especially a Subscription) with multiple payment,
# staged on a long period rather than with a single payment
class RepaymentSchedule < ApplicationRecord
  belongs_to :scheduled, polymorphic: true
  belongs_to :wallet_transaction
  belongs_to :coupon
  belongs_to :invoicing_profile
  belongs_to :operator_profile, foreign_key: :operator_profile_id, class_name: 'InvoicingProfile'
end
