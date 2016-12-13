class Coupon < ActiveRecord::Base
  has_many :invoices

  after_commit :create_stripe_coupon, on: [:create]
  after_commit :delete_stripe_coupon, on: [:destroy]

  validates :name, presence: true
  validates :code, presence: true
  validates :code, format: { with: /\A[A-Z0-9\-]+\z/ ,message: 'only caps letters, numbers, and dashes'}
  validates :code, uniqueness: true
  validates :validity_per_user, presence: true
  validates :validity_per_user, inclusion: { in: %w(once forever) }
  validates_with CouponDiscountValidator
  validates_with CouponExpirationValidator

  def safe_destroy
    if self.invoices.size == 0
      destroy
    else
      false
    end
  end

  ##
  # Check the status of the current coupon. The coupon:
  # - may have been disabled by an admin,
  # - may has expired because the validity date has been reached,
  # - may have been used the maximum number of times it was allowed
  # - may have already been used by the provided user, if the coupon is configured to allow only one use per user,
  # - may exceed the current cart's total amount, if the coupon is configured to discount an amount (and not a percentage)
  # - may be available for use
  # @param [user_id] {Number} if provided and if the current coupon's validity_per_user == 'once', check that the coupon
  # was already used by the provided user
  # @param [amount] {Number} if provided and if the current coupon's type == 'amont_off' check that the coupon
  # does not exceed the cart total price
  # @return {String} status identifier
  ##
  def status(user_id = nil, amount = nil)
    if not active?
      'disabled'
    elsif (!valid_until.nil?) and valid_until.at_end_of_day < DateTime.now
      'expired'
    elsif (!max_usages.nil?) and invoices.count >= max_usages
      'sold_out'
    elsif (!user_id.nil?) and validity_per_user == 'once' and users_ids.include?(user_id.to_i)
      'already_used'
    elsif (!amount.nil?) and type == 'amount_off' and amount_off > amount.to_f
      'amount_exceeded'
    else
      'active'
    end
  end

  def type
    if amount_off.nil? and !percent_off.nil?
      'percent_off'
    elsif percent_off.nil? and !amount_off.nil?
      'amount_off'
    end
  end

  def users
    self.invoices.map do |i|
      i.user
    end
  end

  def users_ids
    users.map do |u|
      u.id
    end
  end

  def send_to(user_id)
    NotificationCenter.call type: 'notify_member_about_coupon',
                            receiver: User.find(user_id),
                            attached_object: self
  end

  private
  def create_stripe_coupon
    StripeWorker.perform_async(:create_stripe_coupon, id)
  end

  def delete_stripe_coupon
    StripeWorker.perform_async(:delete_stripe_coupon, code)
  end

end
