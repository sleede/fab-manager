# frozen_string_literal: true

# Reservation is a Slot or a Ticket booked by a member.
# Slots are for Machine, Space and Training reservations.
# Tickets are for Event reservations.
class Reservation < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  belongs_to :statistic_profile

  has_many :slots_reservations, dependent: :destroy
  has_many :slots, through: :slots_reservations

  accepts_nested_attributes_for :slots, allow_destroy: true
  belongs_to :reservable, polymorphic: true

  has_many :tickets
  accepts_nested_attributes_for :tickets, allow_destroy: false

  has_many :invoice_items, as: :object, dependent: :destroy
  has_one :payment_schedule_object, as: :object, dependent: :destroy

  validates_presence_of :reservable_id, :reservable_type
  validate :machine_not_already_reserved, if: -> { reservable.is_a?(Machine) }
  validate :training_not_fully_reserved, if: -> { reservable.is_a?(Training) }
  validate :slots_not_locked

  after_commit :notify_member_create_reservation, on: :create
  after_commit :notify_admin_member_create_reservation, on: :create
  after_commit :extend_subscription, on: :create
  after_save :update_event_nb_free_places, if: proc { |reservation| reservation.reservable_type == 'Event' }


  # @param canceled    if true, count the number of seats for this reservation, including canceled seats
  def total_booked_seats(canceled: false)
    # cases:
    # - machine/training/space reservation => 1 slot = 1 seat (currently not covered by this function)
    # - event reservation => seats = nb_reserve_place (normal price) + tickets.booked (other prices)
    return 0 if slots.first.canceled_at && !canceled

    total = nb_reserve_places
    total += tickets.map(&:booked).map(&:to_i).reduce(:+) if tickets.count.positive?

    total
  end

  def user
    statistic_profile.user
  end

  def update_event_nb_free_places
    return unless reservable_type == 'Event'

    reservable.update_nb_free_places
    reservable.save!
  end

  def original_payment_schedule
    payment_schedule_object&.payment_schedule
  end

  def original_invoice
    invoice_items.select(:invoice_id)
                 .group(:invoice_id)
                 .map(&:invoice_id)
                 .map { |id| Invoice.find_by(id: id, type: nil) }
                 .first
  end

  private

  def machine_not_already_reserved
    already_reserved = false
    slots.each do |slot|
      same_hour_slots = Slot.joins(:reservations).where(
        reservations: { reservable_type: reservable_type, reservable_id: reservable_id },
        start_at: slot.start_at,
        end_at: slot.end_at,
        availability_id: slot.availability_id,
        canceled_at: nil
      )
      if same_hour_slots.any?
        already_reserved = true
        break
      end
    end
    errors.add(:machine, 'already reserved') if already_reserved
  end

  def training_not_fully_reserved
    slot = slots.first
    errors.add(:training, 'already fully reserved') if Availability.find(slot.availability_id).completed?
  end

  def slots_not_locked
    # check that none of the reserved availabilities was locked
    slots.each do |slot|
      errors.add(:slots, 'locked') if slot.availability.lock
    end
  end

  def extend_subscription
    SubscriptionExtensionAfterReservation.new(self).extend_subscription_if_eligible
  end

  def notify_member_create_reservation
    NotificationCenter.call type: 'notify_member_create_reservation',
                            receiver: user,
                            attached_object: self
  end

  def notify_admin_member_create_reservation
    NotificationCenter.call type: 'notify_admin_member_create_reservation',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end
end
