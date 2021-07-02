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
        .where('minutes_used < prepaid_packs.minutes')
    end

    # subtract the number of used prepaid minutes from the user's count
    def update_user_minutes(user, reservation)
      # total number of minutes available in user's packs
      available_minutes = minutes_available(user, reservation.reservable)
      return if available_minutes.zero?

      # total number of minutes in the reservation's slots
      slots_minutes = reservation.slots.map do |slot|
        (slot.end_at.to_time - slot.start_at.to_time) / SECONDS_PER_MINUTE
      end
      reservation_minutes = slots_minutes.reduce(:+) || 0

      # total number of prepaid minutes used by this reservation
      consumed = reservation_minutes
      consumed = available_minutes if reservation_minutes > available_minutes

      # subtract the consumed minutes for user's current packs
      packs = user_packs(user, reservation.reservable).order(minutes_used: :desc)
      packs.each do |pack|
        pack_available = pack.prepaid_pack.minutes - pack.minutes_used
        remaining = pack_available - consumed
        remaining = 0 if remaining.negative?
        pack_consumed = pack.prepaid_pack.minutes - remaining
        pack.update_attributes(minutes_used: pack_consumed)

        consumed -= pack_consumed
      end
    end

    ## Total number of prepaid minutes available
    def minutes_available(user, priceable)
      user_packs = user_packs(user, priceable)
      total_available = user_packs.map { |up| up.prepaid_pack.minutes }.reduce(:+) || 0
      total_used = user_packs.map(&:minutes_used).reduce(:+) || 0

      total_available - total_used
    end
  end
end
