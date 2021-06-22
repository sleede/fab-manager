# frozen_string_literal: true

# Provides methods for Prices
class PriceService
  def self.list(filters)
    prices = Price.where(nil)

    prices = prices.where(priceable_type: filters[:priceable_type]) if filters[:priceable_type].present?
    prices = prices.where(priceable_id: filters[:priceable_id]) if filters[:priceable_id].present?
    prices = prices.where(group_id: filters[:group_id]) if filters[:group_id].present?
    if filters[:plan_id].present?
      plan_id = /no|nil|null|undefined/i.match?(filters[:plan_id]) ? nil : filters[:plan_id]
      prices = prices.where(plan_id: plan_id)
    end

    prices
  end
end
