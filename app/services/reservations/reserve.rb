# frozen_string_literal: true

# Provides helper methods for Reservation actions
class Reservations::Reserve
  attr_accessor :user_id, :operator_profile_id

  def initialize(user_id, operator_profile_id)
    @user_id = user_id
    @operator_profile_id = operator_profile_id
  end

  ##
  # Confirm the payment of the given reservation, generate the associated documents and save teh record into
  # the database.
  ##
  def pay_and_save(reservation, payment_details: nil, payment_intent_id: nil, schedule: false, payment_method: nil)
    user = User.find(user_id)
    reservation.statistic_profile_id = StatisticProfile.find_by(user_id: user_id).id

    reservation.pre_check
    payment = if schedule
                generate_schedule(reservation: reservation,
                                  total: payment_details[:before_coupon],
                                  operator_profile_id: operator_profile_id,
                                  user: user,
                                  payment_method: payment_method,
                                  coupon_code: payment_details[:coupon])
              else
                generate_invoice(reservation, operator_profile_id, payment_details, payment_intent_id)
              end
    payment.save
    debit_user_wallet(payment, user, reservation)
    reservation.post_save
    true
  end

  ##
  # Generate the invoice for the given reservation+subscription
  ##
  def generate_schedule(reservation: nil, total: nil, operator_profile_id: nil, user: nil, payment_method: nil, coupon_code: nil)
    operator = InvoicingProfile.find(operator_profile_id)&.user
    coupon = Coupon.find_by(code: coupon_code) unless coupon_code.nil?

    PaymentScheduleService.new.create(
      nil,
      total,
      coupon: coupon,
      operator: operator,
      payment_method: payment_method,
      user: user,
      reservation: reservation
    )
  end

  ##
  # Generate the invoice for the given reservation
  ##
  def generate_invoice(reservation, operator_profile_id, payment_details, payment_intent_id = nil)
    InvoicesService.create(
      payment_details,
      operator_profile_id,
      reservation: reservation,
      payment_intent_id: payment_intent_id
    )
  end

  ##
  # Compute the amount decreased from the user's wallet, if applicable
  # @param payment {Invoice|PaymentSchedule}
  # @param user {User} the customer
  # @param coupon {Coupon|String} Coupon object or code
  ##
  def wallet_amount_debit(payment, user, coupon = nil)
    total = payment.total
    total = CouponService.new.apply(total, coupon, user.id) if coupon

    wallet_amount = (user.wallet.amount * 100).to_i

    wallet_amount >= total ? total : wallet_amount
  end

  ##
  # Subtract the amount of the current reservation from the customer's wallet
  ##
  def debit_user_wallet(payment, user, reservation)
    wallet_amount = wallet_amount_debit(payment, user)
    return unless wallet_amount.present? && wallet_amount != 0

    amount = wallet_amount / 100.0
    wallet_transaction = WalletService.new(user: user, wallet: user.wallet).debit(amount, reservation)
    # wallet debit success
    raise DebitWalletError unless wallet_transaction

    payment.set_wallet_transaction(wallet_amount, wallet_transaction.id)
  end
end
