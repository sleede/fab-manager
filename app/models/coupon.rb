class Coupon < ActiveRecord::Base
  has_many :invoices

  after_commit :create_stripe_coupon, on: [:create]
  after_commit :delete_stripe_coupon, on: [:destroy]

  validates :name, presence: true
  validates :code, presence: true
  validates :code, format: { with: /\A[A-Z0-9]+\z/ ,message: 'only caps letters and numbers'}
  validates :code, uniqueness: true
  validates :percent_off, presence: true
  validates :percent_off, :inclusion => 0..100

  def safe_destroy
    if self.invoices.size == 0
      destroy
    else
      false
    end
  end

  def create_stripe_coupon
    StripeWorker.perform_async(:create_stripe_coupon, id)
  end

  def delete_stripe_coupon
    StripeWorker.perform_async(:delete_stripe_coupon, code)
  end

end
