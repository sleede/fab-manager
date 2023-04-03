# frozen_string_literal: true

# PaymentSchedule is a way for members to pay something (especially a Subscription) with multiple payment,
# staged on a long period rather than with a single payment
class PaymentSchedule < PaymentDocument
  require 'fileutils'

  belongs_to :wallet_transaction
  belongs_to :coupon
  belongs_to :invoicing_profile
  belongs_to :statistic_profile
  belongs_to :operator_profile, class_name: 'InvoicingProfile'

  has_one :chained_element, as: :element, dependent: :restrict_with_exception
  has_many :payment_schedule_items, dependent: :destroy
  has_many :payment_gateway_objects, as: :item, dependent: :destroy
  has_many :payment_schedule_objects, dependent: :destroy

  before_create :add_environment
  after_create :generate_order_number, :update_reference, :chain_record
  after_commit :generate_and_send_document, on: [:create], if: :persisted?
  after_commit :generate_initial_invoice, on: [:create], if: :persisted?

  delegate :footprint, to: :chained_element

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

  def gateway_payment_mean
    payment_gateway_objects.map(&:gateway_object).find(&:payment_mean?)
  end

  def gateway_subscription
    payment_gateway_objects.includes(:payment_gateway_object).map(&:gateway_object).find(&:subscription?)
  end

  def gateway_order
    payment_gateway_objects.map(&:gateway_object).find(&:order?)
  end

  def main_object
    payment_schedule_objects.find_by(main: true)
  end

  delegate :user, to: :invoicing_profile

  # for debug & used by rake task "fablab:maintenance:regenerate_schedules"
  def regenerate_pdf
    pdf = ::Pdf::PaymentSchedule.new(self).render
    File.binwrite(file, pdf)
  end

  def footprint_children
    payment_schedule_items
  end

  def self.columns_out_of_footprint
    %w[payment_method]
  end

  def post_save(*args)
    return unless payment_method == 'card'

    PaymentGatewayService.new.create_subscription(self, *args)
  end

  def render_resource
    { partial: 'api/payment_schedules/payment_schedule', locals: { payment_schedule: self } }
  end

  def to_cart
    service = CartService.new(operator_profile.user)
    service.from_payment_schedule(self)
  end

  private

  def generate_and_send_document
    return unless Setting.get('invoicing_module')

    unless Rails.env.test?
      Rails.logger.info "Creating an PaymentScheduleWorker job to generate the following payment schedule: id(#{id}), " \
                        "main_object.object_id(#{main_object.object_id}), " \
                        "main_object.object_type(#{main_object.object_type}), user_id(#{invoicing_profile.user_id})"
    end
    PaymentScheduleWorker.perform_async(id)
  end

  def generate_initial_invoice
    PaymentScheduleItemWorker.perform_async
  end
end
