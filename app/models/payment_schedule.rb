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

  before_create :add_environment
  after_create :update_reference, :chain_record

  ##
  # This is useful to check the first item because its amount may be different from the others
  ##
  def ordered_items
    payment_schedule_items.order(due_date: :asc)
  end

  def add_environment
    self.environment = Rails.env
  end

  def update_reference
    self.reference = InvoiceReferenceService.generate_reference(self, payment_schedule: true)
    save
  end

  def set_wallet_transaction(amount, transaction_id)
    raise InvalidFootprintError unless check_footprint

    update_columns(wallet_amount: amount, wallet_transaction_id: transaction_id)
    chain_record
  end

  def chain_record
    self.footprint = compute_footprint
    save!
    FootprintDebug.create!(
      footprint: footprint,
      data: FootprintService.footprint_data(PaymentSchedule, self),
      klass: PaymentSchedule.name
    )
  end

  def compute_footprint
    FootprintService.compute_footprint(PaymentSchedule, self)
  end

  def check_footprint
    payment_schedule_items.map(&:check_footprint).all? && footprint == compute_footprint
  end
end
