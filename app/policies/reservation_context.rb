# frozen_string_literal: true

# Pundit Additional context to validate the price of a reservation
class ReservationContext
  attr_reader :reservation, :price

  def initialize(reservation, price)
    @reservation = reservation
    @price = price
  end

  def policy_class
    ReservationPolicy
  end
end
