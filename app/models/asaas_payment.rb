# frozen_string_literal: true

# Stores pending and completed Asaas Pix payments
class AsaasPayment < ApplicationRecord
  belongs_to :item, polymorphic: true, optional: true
  belongs_to :operator, class_name: 'User'
  belongs_to :customer, class_name: 'User'
  belongs_to :result, polymorphic: true, optional: true

  validates :token, :status, presence: true

  scope :pending, -> { where(status: %w[pending waiting_payment]) }

  def paid?
    status == 'paid'
  end

  def expired?
    status == 'expired'
  end

  def failed?
    status == 'failed'
  end
end
