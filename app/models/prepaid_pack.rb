# frozen_string_literal: true

# Prepaid-packs of hours for machines/spaces.
#
# A prepaid-pack is a set a hours that can be bought by a member. After having bought one, a member will be able to book, for free,
# as much hours as there is in the pack, until the validity has not expired.
#
# The number of hours in a pack is stored in minutes.
class PrepaidPack < ApplicationRecord
  belongs_to :priceable, polymorphic: true
  belongs_to :machine, foreign_type: 'Machine', foreign_key: 'priceable_id'
  belongs_to :space, foreign_type: 'Space', foreign_key: 'priceable_id'

  belongs_to :group

  has_many :statistic_profile_prepaid_packs

  validates :amount, :group_id, :priceable_id, :priceable_type, :minutes, presence: true

  def validity
    validity_count.send(validity_interval)
  end

  def destroyable?
    statistic_profile_prepaid_packs.empty?
  end
end
