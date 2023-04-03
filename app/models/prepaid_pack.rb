# frozen_string_literal: true

# Prepaid-packs of hours for machines/spaces.
#
# A prepaid-pack is a set a hours that can be bought by a member. After having bought one, a member will be able to book, for free,
# as much hours as there is in the pack, until the validity has not expired.
#
# The number of hours in a pack is stored in minutes.
class PrepaidPack < ApplicationRecord
  belongs_to :priceable, polymorphic: true
  belongs_to :machine, foreign_key: 'priceable_id', inverse_of: :prepaid_packs
  belongs_to :space, foreign_key: 'priceable_id', inverse_of: :prepaid_packs

  belongs_to :group

  has_many :statistic_profile_prepaid_packs, dependent: :destroy

  has_many :cart_item_prepaid_packs, class_name: 'CartItem::PrepaidPack', dependent: :destroy

  validates :amount, :group_id, :priceable_id, :priceable_type, :minutes, presence: true

  def validity
    return nil if validity_interval.nil?

    validity_count&.send(validity_interval)
  end

  def destroyable?
    statistic_profile_prepaid_packs.empty?
  end
end
