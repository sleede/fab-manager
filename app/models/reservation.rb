class Reservation < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :user
  has_many :slots, dependent: :destroy
  accepts_nested_attributes_for :slots, allow_destroy: true
  belongs_to :reservable, polymorphic: true

  has_many :tickets
  accepts_nested_attributes_for :tickets, allow_destroy: false

  has_one :invoice, -> {where(type: nil)}, as: :invoiced, dependent: :destroy

  validates_presence_of :reservable_id, :reservable_type
  validate :machine_not_already_reserved, if: -> { self.reservable.is_a?(Machine) }
  validate :training_not_fully_reserved, if: -> { self.reservable.is_a?(Training) }

  attr_accessor :card_token, :plan_id, :subscription

  after_commit :notify_member_create_reservation, on: :create
  after_commit :notify_admin_member_create_reservation, on: :create
  after_save :update_event_nb_free_places, if: Proc.new { |reservation| reservation.reservable_type == 'Event' }
  after_create :debit_user_wallet

  ##
  # Generate an array of {Stripe::InvoiceItem} with the elements in the current reservation, price included.
  # The training/machine price is depending of the member's group, subscription and credits already used
  # @param on_site {Boolean} true if an admin triggered the call
  # @param coupon_code {String} pass a valid code to appy a coupon
  ##
  def generate_invoice_items(on_site = false, coupon_code = nil)

    # returning array
    invoice_items = []

    # prepare the plan
    if user.subscribed_plan
      plan = user.subscribed_plan
      new_plan_being_bought = false
    elsif plan_id
      plan = Plan.find(plan_id)
      new_plan_being_bought = true
    else
      plan = nil
    end


    case reservable

      # === Machine reservation ===
      when Machine
        base_amount = reservable.prices.find_by(group_id: user.group_id, plan_id: plan.try(:id)).amount
        users_credits_manager = UsersCredits::Manager.new(reservation: self, plan: plan)

        slots.each_with_index do |slot, index|
          description = reservable.name + " #{I18n.l slot.start_at, format: :long} - #{I18n.l slot.end_at, format: :hour_minute}"

          ii_amount = base_amount # ii_amount default to base_amount

          if users_credits_manager.will_use_credits?
            ii_amount = (index < users_credits_manager.free_hours_count) ? 0 : base_amount
          end

          ii_amount = 0 if slot.offered and on_site # if it's a local payment and slot is offered free

          unless on_site # if it's local payment then do not create Stripe::InvoiceItem
            ii = Stripe::InvoiceItem.create(
                customer: user.stp_customer_id,
                amount: ii_amount,
                currency: Rails.application.secrets.stripe_currency,
                description: description
            )
            invoice_items << ii
          end
          self.invoice.invoice_items.push InvoiceItem.new(amount: ii_amount, stp_invoice_item_id: (ii.id if ii), description: description)
        end


      # === Training reservation ===
      when Training
        base_amount = reservable.amount_by_group(user.group_id).amount

        # be careful, variable plan can be the user's plan OR the plan user is currently purchasing
        users_credits_manager = UsersCredits::Manager.new(reservation: self, plan: plan)
        base_amount = 0 if users_credits_manager.will_use_credits?

        slots.each do |slot|
          description = reservable.name + " #{I18n.l slot.start_at, format: :long} - #{I18n.l slot.end_at, format: :hour_minute}"
          ii_amount = base_amount
          ii_amount = 0 if (slot.offered and on_site)
          unless on_site
            ii = Stripe::InvoiceItem.create(
                customer: user.stp_customer_id,
                amount: ii_amount,
                currency: Rails.application.secrets.stripe_currency,
                description: description
            )
            invoice_items << ii
          end
          self.invoice.invoice_items.push InvoiceItem.new(amount: ii_amount, stp_invoice_item_id: (ii.id if ii), description: description)
        end

      # === Event reservation ===
      when Event
        amount = reservable.amount * nb_reserve_places
        tickets.each do |ticket|
          amount += ticket.booked * ticket.event_price_category.amount
        end
        slots.each do |slot|
          description = "#{reservable.name} "
          (slot.start_at.to_date..slot.end_at.to_date).each do |d|
            description += "\n" if slot.start_at.to_date != slot.end_at.to_date
            description += "#{I18n.l d, format: :long} #{I18n.l slot.start_at, format: :hour_minute} - #{I18n.l slot.end_at, format: :hour_minute}"
          end
          ii_amount = amount
          ii_amount = 0 if (slot.offered and on_site)
          unless on_site
            ii = Stripe::InvoiceItem.create(
                customer: user.stp_customer_id,
                amount: ii_amount,
                currency: Rails.application.secrets.stripe_currency,
                description: description
            )
            invoice_items << ii
          end
          self.invoice.invoice_items.push InvoiceItem.new(amount: ii_amount, stp_invoice_item_id: (ii.id if ii), description: description)
        end

      # === Unknown reservation type ===
      else
        raise NotImplementedError

    end

    # === Coupon ===
    unless coupon_code.nil?
      @coupon = Coupon.find_by(code: coupon_code)
      if not @coupon.nil? and @coupon.status(user.id) == 'active'
        total = get_cart_total

        discount = 0
        if @coupon.type == 'percent_off'
          discount = (total  * @coupon.percent_off / 100).to_i
        elsif @coupon.type == 'amount_off'
          discount = @coupon.amount_off
        else
          raise InvalidCouponError
        end

        unless on_site
          invoice_items << Stripe::InvoiceItem.create(
              customer: user.stp_customer_id,
              amount: -discount,
              currency: Rails.application.secrets.stripe_currency,
              description: "coupon #{@coupon.code}"
          )
        end
      else
        raise InvalidCouponError
      end
    end

    @wallet_amount_debit = get_wallet_amount_debit
    if @wallet_amount_debit != 0 and !on_site
      invoice_items << Stripe::InvoiceItem.create(
        customer: user.stp_customer_id,
        amount: -@wallet_amount_debit,
        currency: Rails.application.secrets.stripe_currency,
        description: "wallet -#{@wallet_amount_debit / 100.0}"
      )
    end

    # let's return the resulting array of items
    invoice_items
  end

  def save_with_payment(coupon_code = nil)
    build_invoice(user: user)
    invoice_items = generate_invoice_items(false, coupon_code)
    if valid?
      # TODO: refactoring
      customer = Stripe::Customer.retrieve(user.stp_customer_id)
      if plan_id
        self.subscription = Subscription.find_or_initialize_by(user_id: user.id)
        self.subscription.attributes = {plan_id: plan_id, user_id: user.id, card_token: card_token, expired_at: nil}
        if subscription.save_with_payment(false)
          self.stp_invoice_id = invoice_items.first.refresh.invoice
          self.invoice.stp_invoice_id = invoice_items.first.refresh.invoice
          self.invoice.invoice_items.push InvoiceItem.new(amount: subscription.plan.amount, stp_invoice_item_id: subscription.stp_subscription_id, description: subscription.plan.name, subscription_id: subscription.id)
          set_total_and_coupon(coupon_code)
          save!
          #
          # IMPORTANT NOTE: here, we don't have to create a stripe::invoice and pay it
          # because subscription.create (in subscription.rb) will pay all waiting stripe invoice items
          #
        else
          # error handling
          invoice_items.each(&:delete)
          errors[:card] << subscription.errors[:card].join
          if subscription.errors[:payment]
            errors[:payment] << subscription.errors[:payment].join
          end
          return false
        end

      else
        begin
          if invoice_items.map(&:amount).map(&:to_i).reduce(:+) > 0
            card = customer.sources.create(card: card_token)
            if customer.default_source.present?
              customer.default_source = card.id
              customer.save
            end
          end
          #
          # IMPORTANT NOTE: here, we have to create an invoice manually and pay it to pay all waiting stripe invoice items
          #
          stp_invoice = Stripe::Invoice.create(
            customer: user.stp_customer_id,
          )
          stp_invoice.pay
          card.delete if card
          self.stp_invoice_id = stp_invoice.id
          self.invoice.stp_invoice_id = stp_invoice.id
          set_total_and_coupon(coupon_code)
          save!
        rescue Stripe::CardError => card_error
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.info card_error
          errors[:card] << card_error.message
          return false
        rescue Stripe::InvalidRequestError => e
          # Invalid parameters were supplied to Stripe's API
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.error e
          errors[:payment] << e.message
          return false
        rescue Stripe::AuthenticationError => e
          # Authentication with Stripe's API failed
          # (maybe you changed API keys recently)
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.error e
          errors[:payment] << e.message
          return false
        rescue Stripe::APIConnectionError => e
          # Network communication with Stripe failed
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.error e
          errors[:payment] << e.message
          return false
        rescue Stripe::StripeError => e
          # Display a very generic error to the user, and maybe send
          # yourself an email
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.error e
          errors[:payment] << e.message
          return false
        rescue => e
          # Something else happened, completely unrelated to Stripe
          clear_payment_info(card, stp_invoice, invoice_items)
          logger.error e
          errors[:payment] << e.message
          return false
        end
      end

      UsersCredits::Manager.new(reservation: self).update_credits
      true
    end
  end

  def clear_payment_info(card, invoice, invoice_items)
    begin
      card.delete if card
      if invoice
        invoice.closed = true
        invoice.save
      end
      if invoice_items.size > 0
        invoice_items.each(&:delete)
      end
    rescue Stripe::InvalidRequestError => e
      logger.error e
    rescue Stripe::AuthenticationError => e
      logger.error e
    rescue Stripe::APIConnectionError => e
      logger.error e
    rescue Stripe::StripeError => e
      logger.error e
    rescue => e
      logger.error e
    end
  end


  def save_with_local_payment(coupon_code = nil)
    if user.invoicing_disabled?
      if valid?

        ### generate invoice only for calcul price, TODO refactor!!
        build_invoice(user: user)
        generate_invoice_items(true, coupon_code)
        @wallet_amount_debit = get_wallet_amount_debit
        self.invoice = nil
        ###

        save!
        UsersCredits::Manager.new(reservation: self).update_credits
        return true
      end
    else
      build_invoice(user: user)
      generate_invoice_items(true, coupon_code)
    end

    if valid?
      if plan_id
        self.subscription = Subscription.find_or_initialize_by(user_id: user.id)
        self.subscription.attributes = {plan_id: plan_id, user_id: user.id, expired_at: nil}
        if subscription.save_with_local_payment(false)
          self.invoice.invoice_items.push InvoiceItem.new(amount: subscription.plan.amount, description: subscription.plan.name, subscription_id: subscription.id)
          set_total_and_coupon(coupon_code)
          save!
        else
          errors[:card] << subscription.errors[:card].join
          return false
        end
      else
        set_total_and_coupon(coupon_code)
        save!
      end

      UsersCredits::Manager.new(reservation: self).update_credits
      return true
    end
  end

  def total_booked_seats
    total = nb_reserve_places
    if tickets.count > 0
      total += tickets.map(&:booked).map(&:to_i).reduce(:+)
    end
    total
  end

  private
  def machine_not_already_reserved
    already_reserved = false
    self.slots.each do |slot|
      same_hour_slots = Slot.joins(:reservation).where(
                        reservations: { reservable_type: self.reservable_type,
                                       reservable_id: self.reservable_id
                                     },
                                       start_at: slot.start_at,
                                       end_at: slot.end_at,
                                       availability_id: slot.availability_id,
                                       canceled_at: nil)
      if same_hour_slots.any?
        already_reserved = true
        break
      end
    end
    errors.add(:machine, "already reserved") if already_reserved
  end

  def training_not_fully_reserved
    slot = self.slots.first
    errors.add(:training, "already fully reserved") if Availability.find(slot.availability_id).is_completed
  end

  private
  def notify_member_create_reservation
    NotificationCenter.call type: 'notify_member_create_reservation',
                            receiver: user,
                            attached_object: self
  end

  def notify_admin_member_create_reservation
    NotificationCenter.call type: 'notify_admin_member_create_reservation',
                            receiver: User.admins,
                            attached_object: self
  end

  def update_event_nb_free_places
    if reservable_id_was.blank?
      # simple reservation creation, we subtract the number of booked seats from the previous number
      nb_free_places = reservable.nb_free_places - total_booked_seats
    else
      # reservation moved from another date (for recurring events)
      seats = total_booked_seats

      reservable_was = Event.find(reservable_id_was)
      nb_free_places = reservable_was.nb_free_places + seats
      reservable_was.update_columns(nb_free_places: nb_free_places)
      nb_free_places = reservable.nb_free_places - seats
    end
    reservable.update_columns(nb_free_places: nb_free_places)
  end

  def get_cart_total
    total = (self.invoice.invoice_items.map(&:amount).map(&:to_i).reduce(:+) or 0)
    if plan_id.present?
      plan = Plan.find(plan_id)
      total += plan.amount
    end
    total
  end

  def get_wallet_amount_debit
    total = get_cart_total
    if @coupon
      total = CouponService.new.apply(total, @coupon, user.id)
    end
    wallet_amount = (user.wallet.amount * 100).to_i

    wallet_amount >= total ? total : wallet_amount
  end

  def debit_user_wallet
    if @wallet_amount_debit.present? and @wallet_amount_debit != 0
      amount = @wallet_amount_debit / 100.0
      wallet_transaction = WalletService.new(user: user, wallet: user.wallet).debit(amount, self)
      # wallet debit success
      if wallet_transaction
        # payment by online or (payment by local and invoice isnt disabled)
        if stp_invoice_id or !user.invoicing_disabled?
          self.invoice.update_columns(wallet_amount: @wallet_amount_debit, wallet_transaction_id: wallet_transaction.id)
        end
      else
        raise DebitWalletError
      end
    end
  end

  ##
  # Set the total price to the reservation's invoice, summing its whole items.
  # Additionally a coupon may be applied to this invoice to make a discount on the total price
  # @param [coupon_code] {String} optional coupon code to apply to the invoice
  ##
  def set_total_and_coupon(coupon_code = nil)
    total = invoice.invoice_items.map(&:amount).map(&:to_i).reduce(:+)

    unless coupon_code.nil?
      cp = Coupon.find_by(code: coupon_code)
      if not cp.nil? and cp.status(user.id) == 'active'
        total = CouponService.new.apply(total, cp, user.id)
        self.invoice.coupon_id = cp.id
      else
        raise InvalidCouponError
      end
    end

    self.invoice.total = total
  end
end
