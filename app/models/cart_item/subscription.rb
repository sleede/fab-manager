# frozen_string_literal: true

# A subscription added to the shopping cart
class CartItem::Subscription < CartItem::BaseItem
  attr_reader :start_at

  def initialize(plan, customer, start_at = nil)
    raise TypeError unless plan.is_a? Plan

    @plan = plan
    @customer = customer
    @start_at = start_at
    super
  end

  def plan
    raise InvalidGroupError if @plan.group_id != @customer.group_id

    @plan
  end

  def price
    amount = plan.amount
    elements = { plan: amount }

    { elements: elements, amount: amount }
  end

  def name
    @plan.base_name
  end

  def to_object
    ::Subscription.new(
      plan_id: @plan.id,
      statistic_profile_id: StatisticProfile.find_by(user: @customer).id,
      start_at: @start_at
    )
  end

  def type
    'subscription'
  end
end
