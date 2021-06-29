# frozen_string_literal: true

# Provides methods for PrepaidPack
class PrepaidPackService
  class << self
    def list(filters)
      packs = PrepaidPack.where(nil)

      packs = packs.where(group_id: filters[:group_id]) if filters[:group_id].present?
      packs = packs.where(priceable_id: filters[:priceable_id]) if filters[:priceable_id].present?
      packs = packs.where(priceable_type: filters[:priceable_type]) if filters[:priceable_type].present?

      if filters[:disabled].present?
        state = filters[:disabled] == 'false' ? [nil, false] : true
        packs = packs.where(disabled: state)
      end

      packs
    end

    def user_packs(user, priceable, threshold)
      query = StatisticProfilePrepaidPack
              .includes(:prepaid_pack)
              .references(:prepaid_packs)
              .where('statistic_profile_id = ?', user.statistic_profile.id)
              .where('expires_at > ?', DateTime.current)
              .where('prepaid_packs.priceable_id = ?', priceable.id)
              .where('prepaid_packs.priceable_type = ?', priceable.class.name)

      if threshold.class == Float
        query = query.where('prepaid_packs.minutes - minutes_used >= prepaid_packs.minutes * ?', threshold)
      elsif threshold.class == Integer
        query = query.where('prepaid_packs.minutes - minutes_used >= ?', threshold)
      end

      query
    end
  end
end
