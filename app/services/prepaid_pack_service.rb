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

    # return the not expired packs for the given item bought by the given user
    def user_packs(user, priceable)
      StatisticProfilePrepaidPack
        .includes(:prepaid_pack)
        .references(:prepaid_packs)
        .where('statistic_profile_id = ?', user.statistic_profile.id)
        .where('expires_at > ?', DateTime.current)
        .where('prepaid_packs.priceable_id = ?', priceable.id)
        .where('prepaid_packs.priceable_type = ?', priceable.class.name)
    end
  end
end
