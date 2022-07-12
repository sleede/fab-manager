# frozen_string_literal: true

# Reservation is a Slot or a Ticket booked by a member.
# Slots are for Machine, Space and Training reservations.
# Tickets are for Event reservations.
class Reservation < ApplicationRecord
  include NotifyWith::NotificationAttachedObject
  include ICalendarConcern

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
    if reservable_type == 'Event'
      # - event reservation => seats = nb_reserve_place (normal price) + tickets.booked (other prices)
      total = nb_reserve_places
      total += tickets.map(&:booked).map(&:to_i).reduce(:+) if tickets.count.positive?

      total = 0 unless slots_reservations.first&.canceled_at.nil?
    else
      # - machine/training/space reservation => 1 slot_reservation = 1 seat
      total = slots_reservations.count
      total -= slots_reservations.where.not(canceled_at: nil).count unless canceled
    end

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

  # Group all slots related to this reservation by dates and by continuous time ranges
  def grouped_slots
    slots_by_date = slots.group_by { |slot| slot[:start_at].to_date }.transform_values { |slots| slots.sort_by { |slot| slot[:start_at] } }
    result = {}
    slots_by_date.each do |date, daily_slots|
      result[date] = { daily_slots.first[:start_at] => [daily_slots.first] }

      daily_slots[1..].each do |slot|
        found = false
        result[date].each do |group_start, group_slots|
          if slot[:start_at] === group_slots.last[:end_at]
            result[date][group_start].push(slot)
            found = true
            break
          end
        end
        result[date][slot[:start_at]] = [slot] unless found
      end
    end
    result
  end

  private

  def machine_not_already_reserved
    slots_reservations.each do |slot|
      same_hour_slots = SlotsReservation.joins(:reservation).where(
        reservations: { reservable_type: reservable_type, reservable_id: reservable_id },
        slot_id: slot_id,
        canceled_at: nil
      ).count
      if same_hour_slots.positive?
        errors.add(:reservable, 'already reserved')
        break
      end
    end
  end

  def training_not_fully_reserved
    full = slots_reservations.map(&:slot).map(&:full?).reduce(:&)
    errors.add(:reservable, 'already fully reserved') if full
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
