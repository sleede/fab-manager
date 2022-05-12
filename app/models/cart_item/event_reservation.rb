# frozen_string_literal: true

# An event reservation added to the shopping cart
class CartItem::EventReservation < CartItem::Reservation
  # @param normal_tickets {Number} number of tickets at the normal price
  # @param other_tickets {Array<{booked: Number, event_price_category_id: Number}>}
  def initialize(customer, operator, event, slots, normal_tickets: 0, other_tickets: [])
    raise TypeError unless event.is_a? Event

    super(customer, operator, event, slots)
    @normal_tickets = normal_tickets || 0
    @other_tickets = other_tickets || []
  end

  def price
    amount = @reservable.amount * @normal_tickets
    is_privileged = @operator.privileged? && @operator.id != @customer.id

    @other_tickets.each do |ticket|
      amount += ticket[:booked] * EventPriceCategory.find(ticket[:event_price_category_id]).amount
    end

    elements = { slots: [] }
    total = 0

    @slots.each do |slot|
      total += get_slot_price(amount,
                              slot,
                              is_privileged,
                              elements: elements,
                              is_division: false)
    end

    { elements: elements, amount: total }
  end

  def to_object
    ::Reservation.new(
      reservable_id: @reservable.id,
      reservable_type: Event.name,
      slots_attributes: slots_params,
      tickets_attributes: tickets_params,
      nb_reserve_places: @normal_tickets,
      statistic_profile_id: StatisticProfile.find_by(user: @customer).id
    )
  end

  def name
    @reservable.title
  end

  def type
    'event'
  end

  protected

  def tickets_params
    @other_tickets.map { |ticket| ticket.permit(:event_price_category_id, :booked) }
  end
end
