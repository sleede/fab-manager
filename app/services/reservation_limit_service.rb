# frozen_string_literal: true

# Check if a user if allowed to book a reservation without exceeding the limits set by his plan
class ReservationLimitService
  class << self
    # @param plan [Plan,NilClass]
    # @param customer [User]
    # @param reservation [CartItem::Reservation]
    # @param cart_items [Array<CartItem::BaseItem>]
    # @return [Boolean]
    def authorized?(plan, customer, reservation, cart_items)
      return true if plan.nil? || !plan.limiting

      return true if reservation.nil? || !reservation.is_a?(CartItem::Reservation)

      limit = limit(plan, reservation.reservable)
      return true if limit.nil?

      reservation.cart_item_reservation_slots.group_by { |sr| sr.slot.start_at.to_date }.each_pair do |date, reservation_slots|
        daily_duration = reservations_duration(customer, date, reservation, cart_items) +
                         (reservation_slots.map { |sr| sr.slot.duration }.reduce(:+) || 0)
        return false if Rational(daily_duration / 3600).to_f > limit
      end

      true
    end

    # @param plan [Plan,NilClass]
    # @param reservable [Machine,Event,Space,Training]
    # @return [Integer,NilClass] in hours
    def limit(plan, reservable)
      return nil unless plan&.limiting

      limitations = plan&.plan_limitations&.filter { |limit| limit.reservables.include?(reservable) }
      limitations&.find { |limit| limit.limitable_type != 'MachineCategory' }&.limit || limitations&.first&.limit
    end

    private

    # @param customer [User]
    # @param date [Date]
    # @param reservation [CartItem::Reservation]
    # @param cart_items [Array<CartItem::BaseItem>]
    # @return [Integer] in seconds
    def reservations_duration(customer, date, reservation, cart_items)
      daily_reservations = customer.reservations
                                   .includes(slots_reservations: :slot)
                                   .where(reservable: reservation.reservable)
                                   .where(slots_reservations: { canceled_at: nil })
                                   .where("date_trunc('day', slots.start_at) = :date", date: date)

      cart_daily_reservations = cart_items.filter do |item|
        item.is_a?(CartItem::Reservation) &&
          item != reservation &&
          item.reservable == reservation.reservable &&
          item.cart_item_reservation_slots
              .includes(:slot)
              .where("date_trunc('day', slots.start_at) = :date", date: date)
      end

      (daily_reservations.map { |r| r.slots_reservations.map { |sr| sr.slot.duration } }.flatten.reduce(:+) || 0) +
        (cart_daily_reservations.map { |r| r.cart_item_reservation_slots.map { |sr| sr.slot.duration } }.flatten.reduce(:+) || 0)
    end
  end
end
