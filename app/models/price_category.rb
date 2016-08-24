class PriceCategory < ActiveRecord::Base
  has_many :event_price_category
  has_many :events, through: :event_price_categories

  validates :name, :presence => true
  validates :name, uniqueness: {case_sensitive: false}
  validates :conditions, :presence => true

  def safe_destroy
    if event_price_category.count == 0
      destroy
    else
      false
    end
  end
end
