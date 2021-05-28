# frozen_string_literal: true

# OfferDay provides a way for admins to extend the subscription of a member for free.
class OfferDay < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :invoice_items, as: :object, dependent: :destroy
  belongs_to :subscription

  # buying invoice
  def original_invoice
    invoice_items.select(:invoice_id)
                 .group(:invoice_id)
                 .map(&:invoice_id)
                 .map { |id| Invoice.find_by(id: id, type: nil) }
                 .first
  end
end
