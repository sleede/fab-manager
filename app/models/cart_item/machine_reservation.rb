# frozen_string_literal: true

# A machine reservation added to the shopping cart
class CartItem::MachineReservation < CartItem::Reservation
  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy, inverse_of: :cart_item,
                                         foreign_type: 'cart_item_type', as: :cart_item
  accepts_nested_attributes_for :cart_item_reservation_slots

  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  belongs_to :reservable, polymorphic: true

  belongs_to :plan

  def type
    'machine'
  end

  def valid?(all_items = [])
    cart_item_reservation_slots.each do |slot|
      same_hour_slots = SlotsReservation.joins(:reservation).where(
        reservations: { reservable: reservable },
        slot_id: slot[:slot_id],
        canceled_at: nil
      ).count
      if same_hour_slots.positive?
        errors.add(:slot, I18n.t('cart_item_validation.reserved'))
        return false
      end
      if reservable.disabled
        errors.add(:reservable, I18n.t('cart_item_validation.machine'))
        return false
      end
      unless reservable.reservable
        errors.add(:reservable, I18n.t('cart_item_validation.reservable'))
        return false
      end
    end

    super
  end

  protected

  def credits
    return 0 if plan.nil?

    machine_credit = plan.machine_credits.find { |credit| credit.creditable_id == reservable.id }
    credits_hours(machine_credit, new_plan_being_bought: new_subscription)
  end

  def reservation_deadline_minutes
    Setting.get('machine_reservation_deadline').to_i
  end
end
