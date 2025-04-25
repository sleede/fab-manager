# frozen_string_literal: true

# Order is a model used to hold orders data
class Order < PaymentDocument
  belongs_to :statistic_profile
  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :coupon
  belongs_to :invoice
  has_many :order_items, dependent: :destroy
  has_one :payment_gateway_object, as: :item, dependent: :destroy
  has_many :order_activities, dependent: :destroy
  has_one :coupon_usage, as: :object, dependent: :destroy

  ALL_STATES = %w[cart paid payment_failed refunded in_progress ready canceled delivered].freeze
  enum state: ALL_STATES.zip(ALL_STATES).to_h

  validates :token, :state, presence: true

  before_create :add_environment
  after_create :update_reference

  delegate :user, to: :statistic_profile

  alias_attribute :order_number, :reference

  def generate_reference(_date = Time.current)
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
