# frozen_string_literal: true

# A subscription extended for free, added to the shopping cart
class CartItem::FreeExtension < CartItem::BaseItem
  belongs_to :customer_profile, class_name: 'InvoicingProfile'
  belongs_to :subscription

  def customer
    statistic_profile.user
  end

  def start_at
    raise InvalidSubscriptionError if subscription.nil?
    if new_expiration_date.nil? || new_expiration_date <= subscription.expired_at
      raise InvalidSubscriptionError, I18n.t('cart_items.must_be_after_expiration')
    end

    subscription.expired_at
  end

  def price
    elements = { OfferDay: 0 }

    { elements: elements, amount: 0 }
  end

  def name
    I18n.t('cart_items.free_extension', **{ DATE: I18n.l(new_expiration_date) })
  end

  def to_object
    ::OfferDay.new(
      subscription_id: subscription.id,
      start_at: start_at,
      end_at: new_expiration_date
    )
  end

  def type
    'subscription'
  end
end
