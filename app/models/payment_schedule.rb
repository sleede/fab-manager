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
  after_commit :generate_and_send_document, on: [:create], if: :persisted?

  def file
    dir = "payment_schedules/#{invoicing_profile.id}"

    # create directories if they doesn't exists (payment_schedules & invoicing_profile_id)
    FileUtils.mkdir_p dir
    "#{dir}/#{filename}"
  end

  def filename
    prefix = Setting.find_by(name: 'payment_schedule_prefix').value_at(created_at)
    prefix ||= if created_at < Setting.find_by(name: 'payment_schedule_prefix').first_update
                 Setting.find_by(name: 'payment_schedule_prefix').first_value
               else
                 Setting.get('payment_schedule_prefix')
               end
    "#{prefix}-#{id}_#{created_at.strftime('%d%m%Y')}.pdf"
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

  private

  def generate_and_send_document
    return unless Setting.get('invoicing_module')

    unless Rails.env.test?
      puts "Creating an InvoiceWorker job to generate the following invoice: id(#{id}), invoiced_id(#{invoiced_id}), " \
           "invoiced_type(#{invoiced_type}), user_id(#{invoicing_profile.user_id})"
    end
    InvoiceWorker.perform_async(id, user&.subscription&.expired_at)
  end
end
