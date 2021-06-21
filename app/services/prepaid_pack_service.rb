# frozen_string_literal: true

# Provides methods for PrepaidPack
class PrepaidPackService
  def self.list(filters)
    packs = PrepaidPack.where(nil)

    packs = packs.where(group_id: filters[:group_id]) if filters[:group_id].present?
    packs = packs.where(priceable_id: filters[:priceable_id]) if filters[:priceable_id].present?
    packs = packs.where(priceable_type: filters[:priceable_type]) if filters[:priceable_type].present?

    packs
  end
end
