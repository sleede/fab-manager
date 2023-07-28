# frozen_string_literal: true

# A Time range, slicing an Availability.
# Slots duration are defined globally by Setting.get('slot_duration') but can be
# overridden per availability.
class Slot < ApplicationRecord
  include NotificationAttachedObject

  has_many :slots_reservations, dependent: :destroy
  has_many :reservations, through: :slots_reservations
  belongs_to :availability

  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy

  after_create_commit :create_places_cache

  attr_accessor :is_blocked

  # @param reservable [Machine,Space,Training,Event,NilClass]
  # @return [Integer] the total number of reserved places
  def reserved_places(reservable = nil)
    if reservable.nil?
      places.pluck('reserved_places').reduce(:+)
    else
      places.detect { |p| p['reservable_type'] == reservable.class.name && p['reservable_id'] == reservable.id }['reserved_places']
    end
  end

  # @param reservables [Array<Machine,Space,Training,Event>,NilClass]
  # @return [Array<Integer>] Collection of User's IDs
  def reserved_users(reservables = nil)
    if reservables.nil?
      places.pluck('user_ids').flatten
    else
      r_places = places.select do |p|
        reservables.any? { |r| r.class.name == p['reservable_type'] && r.id == p['reservable_id'] } # rubocop:disable Style/ClassEqualityComparison
      end
      r_places.pluck('user_ids').flatten
    end
  end

  # @param user_id [Integer,NilClass]
  # @param reservables [Array<Machine,Space,Training,Event>,NilClass]
  # @return [Boolean]
  def reserved_by?(user_id, reservables = nil)
    reserved_users(reservables).include?(user_id)
  end

  # @param reservable [Machine, Space, Training, Event, NilClass]
  # @return [Boolean] enough reservation to fill the whole slot?
  def full?(reservable = nil)
    availability_places = availability.available_places_per_slot(reservable)
    return false if availability_places.nil?

    reserved_places(reservable) >= availability_places
  end

  # @param reservable [Machine,Space,Training,Event,NilClass]
  # @return [Boolean] any reservation or none?
  def reserved?(reservable = nil)
    reserved_places(reservable).positive?
  end

  # @param reservable [Machine,Space,Training,Event,NilClass]
  # @return [Boolean] no reservations at all?
  def empty?(reservable = nil)
    reserved_places(reservable).zero?
  end

  # @param operator_role [String,NilClass] 'admin' | 'manager' | 'member'
  # @param user_id [Integer]
  # @param reservable [Machine,Space,Training,Event,NilClass]
  # @return [Boolean] the reservation on this slot can be modified?
  def modifiable?(operator_role, user_id, reservable = nil)
    %w[admin manager].include?(operator_role) || reserved_by?(user_id, [reservable])
  end

  def duration
    (end_at - start_at).seconds
  end

  private

  def create_places_cache
    Slots::PlacesCacheService.refresh(self)
  end
end
