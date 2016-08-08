class Coupon < ActiveRecord::Base
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true
  validates :code, format: { with: /\A[A-Z0-9]+\z/ ,message: 'only caps letters and numbers'}
  validates :percent_off, presence: true
  validates :percent_off, :inclusion => 0..100

  def safe_destroy
    if self.invoices.size == 0
      destroy
    else
      false
    end
  end

end
