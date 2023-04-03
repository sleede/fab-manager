# frozen_string_literal: true

# A subscription added to the shopping cart
class CartItem::Subscription < CartItem::BaseItem
  belongs_to :plan
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  def customer
    customer_profile.user
  end

  def price
    amount = plan.amount
    elements = { plan: amount }

    { elements: elements, amount: amount }
  end

  def name
    plan.base_name
  end

  def to_object
    ::Subscription.new(
      plan_id: plan.id,
      statistic_profile_id: StatisticProfile.find_by(user: customer).id,
      start_at: start_at
    )
  end

  def type
    'subscription'
  end

  def valid?(_all_items)
    if plan.disabled
      errors.add(:plan, I18n.t('cart_item_validation.plan'))
      return false
    end
    if plan.group_id != customer.group_id
      errors.add(:group, I18n.t('cart_item_validation.plan_group', **{ GROUP: plan.group.name }))
      return false
    end
    true
  end
end
