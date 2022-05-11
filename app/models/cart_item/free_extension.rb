# frozen_string_literal: true

# A subscription extended for free, added to the shopping cart
class CartItem::FreeExtension < CartItem::BaseItem
  def initialize(customer, subscription, new_expiration_date)
    raise TypeError unless subscription.is_a? Subscription

    @customer = customer
    @new_expiration_date = new_expiration_date
    @subscription = subscription
    super
  end

  def start_at
    raise InvalidSubscriptionError if @subscription.nil?
    raise InvalidSubscriptionError if @new_expiration_date <= @subscription.expired_at

    @subscription.expired_at
  end

  def price
    elements = { OfferDay: 0 }

    { elements: elements, amount: 0 }
  end

  def name
    I18n.t('cart_items.free_extension', DATE: I18n.l(@new_expiration_date))
  end

  def to_object
    ::OfferDay.new(
      subscription_id: @subscription.id,
      start_at: start_at,
      end_at: @new_expiration_date
    )
  end

  def type
    'subscription'
  end
end
