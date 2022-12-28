# frozen_string_literal: true

# A Time range, slicing an Availability.
# Slots duration are defined globally by Setting.get('slot_duration') but can be
# overridden per availability.
class Slot < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :slots_reservations, dependent: :destroy
  has_many :reservations, through: :slots_reservations
  belongs_to :availability

  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy

  attr_accessor :is_reserved, :machine, :space, :title, :can_modify, :current_user_slots_reservations_ids

  def full?(reservable = nil)
    availability_places = availability.available_places_per_slot(reservable)
    return false if availability_places.nil?

    if reservable.nil?
      slots_reservations.where(canceled_at: nil).count >= availability_places
    else
      slots_reservations.includes(:reservation).where(canceled_at: nil).where('reservations.reservable': reservable).count >= availability_places
    end
  end

  def empty?(reservable = nil)
    if reservable.nil?
      slots_reservations.where(canceled_at: nil).count.zero?
    else
      slots_reservations.includes(:reservation).where(canceled_at: nil).where('reservations.reservable': reservable).count.zero?
    end
  end

  def duration
    (end_at - start_at).seconds
  end
end
