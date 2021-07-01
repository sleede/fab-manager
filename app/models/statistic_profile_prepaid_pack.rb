# frozen_string_literal: true

# Associate a customer with a bought prepaid-packs of hours for machines/spaces.
# Also saves the amount of hours used
class StatisticProfilePrepaidPack < ApplicationRecord
  belongs_to :prepaid_pack
  belongs_to :statistic_profile

  has_many :invoice_items, as: :object, dependent: :destroy
  has_one :payment_schedule_object, as: :object, dependent: :destroy

  before_create :set_expiration_date

  private

  def set_expiration_date
    self.expires_at = DateTime.current + prepaid_pack.validity
  end
end
