# frozen_string_literal: true

# A Time range, slicing an Availability.
# Slots duration are defined globally by Setting.get('slot_duration') but can be
# overridden per availability.
class Slot < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :slots_reservations, dependent: :destroy
  has_many :reservations, through: :slots_reservations
  belongs_to :availability

  attr_accessor :is_reserved, :machine, :space, :title, :can_modify, :is_reserved_by_current_user

  def complete?
    reservations.length >= availability.nb_total_places
  end
end
