# frozen_string_literal: true

# Links an object bought and a payment schedule used to pay this object
class PaymentScheduleObject < Footprintable
  belongs_to :object, polymorphic: true
  belongs_to :reservation, foreign_key: 'object_id', inverse_of: :payment_schedule_object
  belongs_to :subscription, foreign_key: 'object_id', inverse_of: :payment_schedule_object
  belongs_to :statistic_profile_prepaid_pack, foreign_key: 'object_id', inverse_of: :payment_schedule_object
  belongs_to :payment_schedule
  # Re-chaining keeps older elements; the latest one is authoritative
  has_one :chained_element, -> { order(id: :desc) }, inverse_of: false, as: :element, dependent: :restrict_with_exception

  after_create :chain_record

  delegate :footprint, to: :chained_element
end
