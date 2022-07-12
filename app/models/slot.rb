# frozen_string_literal: true

# A Time range, slicing an Availability.
# Slots duration are defined globally by Setting.get('slot_duration') but can be
# overridden per availability.
class Slot < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :slots_reservations, dependent: :destroy
  has_many :reservations, through: :slots_reservations
  belongs_to :availability

  attr_accessor :is_reserved, :machine, :space, :title, :can_modify, :current_user_slots_reservations_ids

  def full?
    slots_reservations.where(canceled_at: nil).count >= availability.available_places_per_slot
  end
end
