# frozen_string_literal: true

# A prepaid-pack added to the shopping cart
class CartItem::PrepaidPack < CartItem::BaseItem
  belongs_to :prepaid_pack
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  def customer
    customer_profile.user
  end

  def pack
    prepaid_pack
  end

  def price
    amount = pack.amount
    elements = { pack: amount }

    { elements: elements, amount: amount }
  end

  def name
    "#{pack.minutes / 60} h"
  end

  def to_object
    ::StatisticProfilePrepaidPack.new(
      prepaid_pack_id: pack.id,
      statistic_profile_id: StatisticProfile.find_by(user: customer).id
    )
  end

  def type
    'pack'
  end

  def valid?(_all_items)
    if pack.disabled
      errors.add(:prepaid_pack, I18n.t('cart_item_validation.pack'))
      return false
    end
    if pack.group_id != customer.group_id
      errors.add(:group, I18n.t('cart_item_validation.pack_group', **{ GROUP: pack.group.name }))
      return false
    end
    true
  end
end
