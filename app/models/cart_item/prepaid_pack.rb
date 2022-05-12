# frozen_string_literal: true

# A prepaid-pack added to the shopping cart
class CartItem::PrepaidPack < CartItem::BaseItem
  def initialize(pack, customer)
    raise TypeError unless pack.is_a? PrepaidPack

    @pack = pack
    @customer = customer
    super
  end

  def pack
    raise InvalidGroupError if @pack.group_id != @customer.group_id

    @pack
  end

  def price
    amount = pack.amount
    elements = { pack: amount }

    { elements: elements, amount: amount }
  end

  def name
    "#{@pack.minutes / 60} h"
  end

  def to_object
    ::StatisticProfilePrepaidPack.new(
      prepaid_pack_id: @pack.id,
      statistic_profile_id: StatisticProfile.find_by(user: @customer).id
    )
  end

  def type
    'pack'
  end
end
