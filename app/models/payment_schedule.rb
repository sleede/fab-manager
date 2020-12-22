# frozen_string_literal: true

# PaymentSchedule is a way for members to pay something (especially a Subscription) with multiple payment,
# staged on a long period rather than with a single payment
class PaymentSchedule < PaymentDocument
  require 'fileutils'

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

  def file
    dir = "payment_schedules/#{invoicing_profile.id}"

    # create directories if they doesn't exists (payment_schedules & invoicing_profile_id)
    FileUtils.mkdir_p dir
    "#{dir}/#{filename}"
  end

  def filename
    prefix = Setting.find_by(name: 'invoice_prefix').value_at(created_at)
    prefix ||= if created_at < Setting.find_by(name: 'invoice_prefix').history_values.order(created_at: :asc).limit(1).first.created_at
                 Setting.find_by(name: 'invoice_prefix').history_values.order(created_at: :asc).limit(1).first
               else
                 Setting.find_by(name: 'invoice_prefix')..history_values.order(created_at: :desc).limit(1).first
               end
    "#{prefix.value}-#{id}_#{created_at.strftime('%d%m%Y')}.pdf"
  end

  ##
  # This is useful to check the first item because its amount may be different from the others
  ##
  def ordered_items
    payment_schedule_items.order(due_date: :asc)
  end

  def check_footprint
    payment_schedule_items.map(&:check_footprint).all? && footprint == compute_footprint
  end
end
