# frozen_string_literal: true

# Subscription is an active or archived subscription of an User to a Plan
class Subscription < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  belongs_to :plan
  belongs_to :statistic_profile

  has_one :payment_schedule_object, as: :object, dependent: :destroy
  has_one :payment_gateway_object, as: :item, dependent: :destroy
  has_many :invoice_items, as: :object, dependent: :destroy
  has_many :offer_days, dependent: :destroy

  has_many :cart_item_free_extensions, class_name: 'CartItem::FreeExtension', dependent: :destroy

  validates :plan_id, presence: true
  validates_with SubscriptionGroupValidator

  # creation
  before_create :set_expiration_date
  after_save :notify_member_subscribed_plan
  after_save :notify_admin_subscribed_plan
  after_save :notify_partner_subscribed_plan, if: :of_partner_plan?

  delegate :user, to: :statistic_profile

  def generate_and_save_invoice(operator_profile_id)
    generate_invoice(operator_profile_id).save
  end

  def expire(time)
    if expired?
      false
    else
      update_columns(expiration_date: time, canceled_at: time) # rubocop:disable Rails/SkipsModelValidations
      notify_admin_subscription_canceled
      notify_member_subscription_canceled
      true
    end
  end

  def expired?
    expired_at <= Time.current
  end

  def expired_at
    last_offered = offer_days.order(:end_at).last
    return last_offered.end_at if last_offered

    expiration_date
  end

  def original_payment_schedule
    payment_schedule_object&.payment_schedule
  end

  # buying invoice
  def original_invoice
    invoice_items.select(:invoice_id)
                 .group(:invoice_id)
                 .map(&:invoice_id)
                 .map { |id| Invoice.find_by(id: id, type: nil) }
                 .first
  end

  private

  def notify_member_subscribed_plan
    NotificationCenter.call type: 'notify_member_subscribed_plan',
                            receiver: user,
                            attached_object: self
  end

  def notify_admin_subscribed_plan
    NotificationCenter.call type: 'notify_admin_subscribed_plan',
                            receiver: User.admins,
                            attached_object: self
  end

  def notify_admin_subscription_canceled
    NotificationCenter.call type: 'notify_admin_subscription_canceled',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end

  def notify_member_subscription_canceled
    NotificationCenter.call type: 'notify_member_subscription_canceled',
                            receiver: user,
                            attached_object: self
  end

  def notify_partner_subscribed_plan
    NotificationCenter.call type: 'notify_partner_subscribed_plan',
                            receiver: plan.partners,
                            attached_object: self
  end

  def notify_subscription_extended
    meta_data = { free_days: false }
    NotificationCenter.call type: :notify_member_subscription_extended,
                            receiver: user,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_admin_subscription_extended,
                            receiver: User.admins_and_managers,
                            attached_object: self,
                            meta_data: meta_data
  end

  def set_expiration_date
    start_at = self.start_at || Time.current
    self.expiration_date = start_at + plan.duration
  end

  def of_partner_plan?
    plan.is_a?(PartnerPlan)
  end
end
