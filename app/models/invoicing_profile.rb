# frozen_string_literal: true

# This table will save the user's profile data needed for legal accounting (invoices, wallet, etc.)
# Legal accounting must be kept for 10 years but GDPR requires that an user can delete his account at any time.
# The data will be kept even if the user is deleted, but it will be unlinked from the user's account.
class InvoicingProfile < ApplicationRecord
  belongs_to :user
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true
  has_one :organization, dependent: :destroy
  accepts_nested_attributes_for :organization, allow_destroy: false
  has_many :invoices, dependent: :destroy
  has_many :payment_schedules, dependent: :destroy

  has_one :wallet, dependent: :destroy
  has_many :wallet_transactions, dependent: :destroy

  has_many :history_values, dependent: :nullify

  has_many :operated_invoices, foreign_key: :operator_profile_id, class_name: 'Invoice', dependent: :nullify, inverse_of: :operator_profile
  has_many :operated_payment_schedules, foreign_key: :operator_profile_id, class_name: 'PaymentSchedule',
                                        dependent: :nullify, inverse_of: :operator_profile

  has_many :user_profile_custom_fields, dependent: :destroy
  has_many :profile_custom_fields, through: :user_profile_custom_fields
  accepts_nested_attributes_for :user_profile_custom_fields, allow_destroy: true

  has_many :accounting_lines, dependent: :destroy

  # as operator
  has_many :operated_cart_item_event_reservations, class_name: 'CartItem::EventReservation', dependent: :nullify, inverse_of: :operator_profile
  has_many :operated_cart_item_machine_reservations, class_name: 'CartItem::MachineReservation', dependent: :nullify,
                                                     inverse_of: :operator_profile
  has_many :operated_cart_item_space_reservations, class_name: 'CartItem::SpaceReservation', dependent: :nullify, inverse_of: :operator_profile
  has_many :operated_cart_item_training_reservations, class_name: 'CartItem::TrainingReservation', dependent: :nullify,
                                                      inverse_of: :operator_profile
  has_many :operated_cart_item_coupon, class_name: 'CartItem::Coupon', dependent: :nullify, inverse_of: :operator_profile
  # as customer
  has_many :cart_item_event_reservations, class_name: 'CartItem::EventReservation', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_machine_reservations, class_name: 'CartItem::MachineReservation', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_space_reservations, class_name: 'CartItem::SpaceReservation', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_training_reservations, class_name: 'CartItem::TrainingReservation', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_free_extensions, class_name: 'CartItem::FreeExtension', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_subscriptions, class_name: 'CartItem::Subscription', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_prepaid_packs, class_name: 'CartItem::PrepaidPack', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_coupons, class_name: 'CartItem::Coupon', dependent: :destroy, inverse_of: :customer_profile
  has_many :cart_item_payment_schedules, class_name: 'CartItem::PaymentSchedule', dependent: :destroy, inverse_of: :customer_profile

  before_validation :set_external_id_nil
  validates :external_id, uniqueness: true, allow_blank: true
  validates :address, presence: true, if: -> { Setting.get('address_required') }

  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    "#{(first_name || '').humanize.titleize} #{(last_name || '').humanize.titleize}"
  end

  def invoicing_address
    if organization&.address
      organization.address.address
    elsif address
      address.address
    else
      ''
    end
  end

  private

  def set_external_id_nil
    self.external_id = nil if external_id.blank?
  end
end
