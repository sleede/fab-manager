# frozen_string_literal: true

# An event reservation added to the shopping cart
class CartItem::EventReservation < CartItem::Reservation
  self.table_name = 'cart_item_event_reservations'

  has_many :cart_item_event_reservation_tickets, class_name: 'CartItem::EventReservationTicket', dependent: :destroy,
                                                 inverse_of: :cart_item_event_reservation,
                                                 foreign_key: 'cart_item_event_reservation_id'
  accepts_nested_attributes_for :cart_item_event_reservation_tickets

  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy, inverse_of: :cart_item,
                                         foreign_type: 'cart_item_type', as: :cart_item
  accepts_nested_attributes_for :cart_item_reservation_slots

  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  belongs_to :event

  def reservable
    event
  end

  def reservable_id
    event_id
  end

  def reservable_type
    'Event'
  end

  def price
    amount = reservable.amount * normal_tickets
    is_privileged = operator.privileged? && operator.id != customer.id

    cart_item_event_reservation_tickets.each do |ticket|
      amount += ticket.booked * ticket.event_price_category.amount
    end

    elements = { slots: [] }
    total = 0

    cart_item_reservation_slots.each do |sr|
      total += get_slot_price(amount,
                              sr,
                              is_privileged,
                              elements: elements,
                              is_division: false)
    end

    { elements: elements, amount: total }
  end

  def to_object
    ::Reservation.new(
      reservable_id: reservable.id,
      reservable_type: Event.name,
      slots_reservations_attributes: slots_params,
      tickets_attributes: cart_item_event_reservation_tickets.map do |t|
        {
          event_price_category_id: t.event_price_category_id,
          booked: t.booked
        }
      end,
      nb_reserve_places: normal_tickets,
      statistic_profile_id: StatisticProfile.find_by(user: customer).id
    )
  end

  def name
    reservable.title
  end

  def type
    'event'
  end

  def total_tickets
    (normal_tickets || 0) + (cart_item_event_reservation_tickets.map(&:booked).reduce(:+) || 0)
  end

  def reservation_deadline_minutes
    Setting.get('event_reservation_deadline').to_i
  end
end
