# frozen_string_literal: true

# A space reservation added to the shopping cart
class CartItem::SpaceReservation < CartItem::Reservation
  # @param plan {Plan} a subscription bought at the same time of the reservation OR an already running subscription
  # @param new_subscription {Boolean} true is new subscription is being bought at the same time of the reservation
  def initialize(customer, operator, space, slots, plan: nil, new_subscription: false)
    raise TypeError unless space.is_a? Space

    super(customer, operator, space, slots)
    @plan = plan
    @space = space
    @new_subscription = new_subscription
  end

  def to_object
    ::Reservation.new(
      reservable_id: @reservable.id,
      reservable_type: Space.name,
      slots_reservations_attributes: slots_params,
      statistic_profile_id: StatisticProfile.find_by(user: @customer).id
    )
  end

  def type
    'space'
  end

  def valid?(all_items)
    if @space.disabled
      @errors[:reservable] = I18n.t('cart_item_validation.space')
      return false
    end

    super
  end

  protected

  def credits
    return 0 if @plan.nil?

    space_credit = @plan.space_credits.find { |credit| credit.creditable_id == @reservable.id }
    credits_hours(space_credit, new_plan_being_bought: @new_subscription)
  end
end
