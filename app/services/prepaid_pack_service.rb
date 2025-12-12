# frozen_string_literal: true

# Provides methods for PrepaidPack
class PrepaidPackService
  class << self
    # @param filters [Hash{Symbol=>Integer,String}]
    # @option filters [Integer] :group_id
    # @option filters [Integer] :priceable_id
    # @option filters [String] :priceable_type 'Machine' | 'Space'
    # @return [ActiveRecord::Relation<PrepaidPack>]
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
    # @param user [User]
    # @param priceable [Machine,Space,NilClass]
    # @return [ActiveRecord::Relation<StatisticProfilePrepaidPack>]
    def user_packs(user, priceable = nil)
      sppp = StatisticProfilePrepaidPack.includes(:prepaid_pack)
                                        .references(:prepaid_packs)
                                        .where(statistic_profile_id: user.statistic_profile.id)
                                        .where('expires_at > ? OR expires_at IS NULL', Time.current)
                                        .where('minutes_used < prepaid_packs.minutes')
      unless priceable.nil?
        sppp = sppp.where(prepaid_packs: { priceable_id: priceable.id })
                   .where(prepaid_packs: { priceable_type: priceable.class.name })
      end
      sppp
    end

    # subtract the number of used prepaid minutes from the user's count
    # @param user [User]
    # @param reservation [Reservation]
    def update_user_minutes(user, reservation)
      # total number of minutes available in user's packs
      available_minutes = minutes_available(user, reservation.reservable)
      return if available_minutes.zero?

      # total number of minutes in the reservation's slots
      slots_minutes = SlotsReservation.includes(:slot).where(reservation_id: reservation.id, offered: false).map do |sr|
        (sr.slot.end_at.to_time - sr.slot.start_at.to_time) / 60.0
      end
      reservation_minutes = slots_minutes.reduce(:+) || 0

      # total number of prepaid minutes used by this reservation
      consumed = reservation_minutes
      consumed = available_minutes if reservation_minutes > available_minutes

      # subtract the consumed minutes for user's current packs
      packs = user_packs(user, reservation.reservable).order(minutes_used: :desc)
      packs.each do |pack|
        pack_available = pack.prepaid_pack.minutes - pack.minutes_used
        remaining = consumed > pack_available ? 0 : pack_available - consumed
        pack.update(minutes_used: pack.prepaid_pack.minutes - remaining)

        pack_consumed = consumed > pack_available ? pack_available : consumed
        consumed -= pack_consumed
        PrepaidPackReservation.create!(statistic_profile_prepaid_pack: pack, reservation: reservation, consumed_minutes: pack_consumed)
      end
    end

    # Total number of prepaid minutes available
    # @param user [User]
    # @param priceable [Machine,Space,NilClass]
    def minutes_available(user, priceable)
      return 0 if Setting.get('pack_only_for_subscription') && !user.subscribed_plan

      user_packs = user_packs(user, priceable)
      total_available = user_packs.map { |up| up.prepaid_pack.minutes }.reduce(:+) || 0
      total_used = user_packs.map(&:minutes_used).reduce(:+) || 0

      total_available - total_used
    end
  end
end
