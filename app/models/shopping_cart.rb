# frozen_string_literal: true

# Stores data about a shopping data
class ShoppingCart
  attr_accessor :customer, :operator, :payment_method, :items, :coupon, :payment_schedule

  # @param items {Array<CartItem::BaseItem>}
  # @param coupon {CartItem::Coupon}
  # @param payment_schedule {CartItem::PaymentSchedule}
  # @param customer {User}
  # @param operator {User}
  def initialize(customer, operator, coupon, payment_schedule, payment_method = '', items: [])
    raise TypeError unless customer.is_a? User

    @customer = customer
    @operator = operator
    @payment_method = payment_method
    @items = items
    @coupon = coupon
    @payment_schedule = payment_schedule
  end

  # compute the price details of the current shopping cart
  def total
    total_amount = 0
    all_elements = { slots: [] }

    @items.map(&:price).each do |price|
      total_amount += price[:amount]
      all_elements = all_elements.merge(price[:elements]) do |_key, old_val, new_val|
        old_val | new_val
      end
    end

    coupon_info = @coupon.price(total_amount)
    schedule_info = @payment_schedule.schedule(coupon_info[:total_with_coupon], coupon_info[:total_without_coupon])

    # return result
    {
      elements: all_elements,
      total: schedule_info[:total].to_i,
      before_coupon: coupon_info[:total_without_coupon].to_i,
      coupon: @coupon.coupon,
      schedule: schedule_info[:schedule]
    }
  end

  # Build the dataset for the current ShoppingCart and save it into the database.
  # Data integrity is guaranteed: all goes right or nothing is saved.
  def build_and_save(payment_id, payment_type)
    price = total
    objects = []
    payment = nil
    ActiveRecord::Base.transaction do
      items.each do |item|
        objects.push(save_item(item))
      end
      update_credits(objects)
      update_packs(objects)

      payment = create_payment_document(price, objects, payment_id, payment_type)
      WalletService.debit_user_wallet(payment, @customer)
      payment.save
      payment.post_save(payment_id)
    end

    success = objects.map(&:errors).flatten.map(&:empty?).all? && items.map(&:errors).map(&:empty?).all?
    errors = objects.map(&:errors).flatten.concat(items.map(&:errors))
    { success: success, payment: payment, errors: errors }
  end

  private

  # Save the object associated with the provided item or raise and Rollback if something wrong append.
  def save_item(item)
    raise ActiveRecord::Rollback unless item.valid?(@items)

    object = item.to_object
    object.save
    raise ActiveRecord::Rollback unless object.errors.empty?

    object
  end

  # Create the PaymentDocument associated with this ShoppingCart and return it
  def create_payment_document(price, objects, payment_id, payment_type)
    if price[:schedule]
      PaymentScheduleService.new.create(
        objects,
        price[:before_coupon],
        coupon: @coupon.coupon,
        operator: @operator,
        payment_method: @payment_method,
        user: @customer,
        payment_id: payment_id,
        payment_type: payment_type
      )
    else
      InvoicesService.create(
        price,
        @operator.invoicing_profile.id,
        objects,
        @customer,
        payment_id: payment_id,
        payment_type: payment_type,
        payment_method: @payment_method
      )
    end
  end

  # Handle the update of the user's credits
  # If a subscription has been bought, the credits must be reset first.
  # Then, the credits related to reservation(s) can be deducted.
  def update_credits(objects)
    subscription = objects.find { |o| o.is_a? Subscription }
    UsersCredits::Manager.new(user: @customer).reset_credits if subscription

    reservations = objects.filter { |o| o.is_a? Reservation }
    reservations.each do |r|
      UsersCredits::Manager.new(reservation: r).update_credits
    end
  end

  # Handle the update of the user's prepaid-packs
  # The total booked minutes are subtracted from the user's prepaid minutes
  def update_packs(objects)
    objects.filter { |o| o.is_a? Reservation }.each do |reservation|
      PrepaidPackService.update_user_minutes(@customer, reservation)
    end
  end
end
