# frozen_string_literal: true

# Pundit Additional context to validate the price of a reservation
class ReservationContext
  attr_reader :reservation, :price, :user_id

  def initialize(reservation, price, user_id)
    @reservation = reservation
    @price = price
    @user_id = user_id
  end

  def policy_class
    ReservationPolicy
  end
end
