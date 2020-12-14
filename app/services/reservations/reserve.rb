# frozen_string_literal: true

# Provides helper methods for Reservation actions
class Reservations::Reserve
  attr_accessor :user_id, :operator_profile_id

  def initialize(user_id, operator_profile_id)
    @user_id = user_id
    @operator_profile_id = operator_profile_id
  end

  def pay_and_save(reservation, payment_details: nil, payment_intent_id: nil, schedule: false)
    reservation.statistic_profile_id = StatisticProfile.find_by(user_id: user_id).id
    reservation.save_with_payment(operator_profile_id, payment_details, payment_intent_id, schedule: schedule)
  end
end
