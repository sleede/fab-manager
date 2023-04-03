# frozen_string_literal: true

# A training reservation added to the shopping cart
class CartItem::TrainingReservation < CartItem::Reservation
  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy, inverse_of: :cart_item,
                                         foreign_type: 'cart_item_type', as: :cart_item
  accepts_nested_attributes_for :cart_item_reservation_slots

  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  belongs_to :reservable, polymorphic: true

  belongs_to :plan

  def price
    base_amount = reservable&.amount_by_group(customer.group_id)&.amount
    is_privileged = operator.admin? || (operator.manager? && operator.id != customer.id)

    elements = { slots: [] }
    amount = 0

    hours_available = credits
    cart_item_reservation_slots.each do |sr|
      amount += get_slot_price(base_amount,
                               sr,
                               is_privileged,
                               elements: elements,
                               has_credits: (customer.training_credits.size < hours_available),
                               is_division: false)
    end

    { elements: elements, amount: amount }
  end

  def type
    'training'
  end

  protected

  def credits
    return 0 if plan.nil?

    is_creditable = plan&.training_credits&.select { |credit| credit.creditable_id == reservable&.id }&.any?
    is_creditable ? plan&.training_credit_nb : 0
  end

  def reservation_deadline_minutes
    Setting.get('training_reservation_deadline').to_i
  end
end
