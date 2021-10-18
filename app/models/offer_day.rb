# frozen_string_literal: true

# OfferDay provides a way for admins to extend the subscription of a member for free.
class OfferDay < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :invoice_items, as: :object, dependent: :destroy
  belongs_to :subscription

  after_create :notify_subscription_extended

  # buying invoice
  def original_invoice
    invoice_items.select(:invoice_id)
                 .group(:invoice_id)
                 .map(&:invoice_id)
                 .map { |id| Invoice.find_by(id: id, type: nil) }
                 .first
  end

  private

  def notify_subscription_extended
    meta_data = { free_days: true }
    NotificationCenter.call type: :notify_member_subscription_extended,
                            receiver: subscription.user,
                            attached_object: subscription,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_admin_subscription_extended,
                            receiver: User.admins_and_managers,
                            attached_object: subscription,
                            meta_data: meta_data
  end

end
