# frozen_string_literal: true

# PriceCategory is a way to segment prices for an Event.
# By default, each Events have a standard price but you may want, for example, to define a reduced fare for students,
# and another reduced fare for children under 8. Each of these prices are defined in an EventPriceCategory.
# You can choose to use each PriceCategory or not, for each Event you create.
class PriceCategory < ApplicationRecord
  has_many :event_price_category
  has_many :events, through: :event_price_categories

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :conditions, presence: true

  def safe_destroy
    if event_price_category.count.zero?
      destroy
    else
      false
    end
  end
end
