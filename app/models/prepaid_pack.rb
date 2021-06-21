# frozen_string_literal: true

# Prepaid-packs of hours for machines/spaces.
# A prepaid-pack is a set a hours that can be bought by a member. The member will be able to book for free as much hours
# as there's in the pack, after having bought one.
# The number of hours in each packs is saved in minutes
class PrepaidPack < ApplicationRecord
  belongs_to :priceable, polymorphic: true
  belongs_to :group

  has_many :user_prepaid_packs

  validates :amount, :group_id, :priceable_id, :priceable_type, :minutes, presence: true

  def hours
    minutes / 60.0
  end

  def safe_destroy
    if user_prepaid_packs.count.zero?
      destroy
    else
      false
    end
  end
end
