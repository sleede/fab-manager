# frozen_string_literal: true

# Order is a model for the user hold information of order
class Order < PaymentDocument
  belongs_to :statistic_profile
  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :coupon
  has_many :order_items, dependent: :destroy
  has_one :payment_gateway_object, as: :item

  ALL_STATES = %w[cart in_progress ready canceled return].freeze
  enum state: ALL_STATES.zip(ALL_STATES).to_h

  PAYMENT_STATES = %w[paid failed refunded].freeze
  enum payment_state: PAYMENT_STATES.zip(PAYMENT_STATES).to_h

  validates :token, :state, presence: true

  before_create :add_environment
  after_create :update_reference

  delegate :user, to: :statistic_profile

  def generate_reference(_date = DateTime.current)
    self.reference = PaymentDocumentService.generate_order_number(self)
  end

  def footprint_children
    order_items
  end

  def paid_by_card?
    !payment_gateway_object.nil? && payment_method == 'card'
  end

  def self.columns_out_of_footprint
    %w[payment_method]
  end
end
