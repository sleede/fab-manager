# frozen_string_literal: true

# EventPriceCategory is the relation table between Event and PriceCategory.
class EventPriceCategory < ApplicationRecord
  belongs_to :event
  belongs_to :price_category

  has_many :tickets

  validates :price_category_id, presence: true
  validates :amount, presence: true

  before_destroy :verify_no_associated_tickets

  protected

  def verify_no_associated_tickets
    throw(:abort) unless tickets.count.zero?
  end

end
